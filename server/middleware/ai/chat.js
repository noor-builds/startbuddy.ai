import { createChatModel } from './llm.js';
import { supabaseAdmin } from '../../db.js';
import { AIMessage, HumanMessage, SystemMessage } from '@langchain/core/messages';

async function handleChat({ authId, startupId, chatId, message }) {
  if (!message || !message.trim()) {
    throw new Error('Message content is required');
  }

  // 1. Fetch startup details
  const { data: startup, error: startupError } = await supabaseAdmin
    .from('startup')
    .select('id, startupName, description')
    .eq('id', startupId)
    .eq('authid', authId)
    .single();

  if (startupError || !startup) {
    throw new Error('Startup not found: ' + (startupError?.message ?? ''));
  }

  let resolvedChatId = chatId;

  // 2. If chatId is not provided, create a new chat session
  if (!resolvedChatId) {
    const { data: newChat, error: chatError } = await supabaseAdmin
      .from('chats')
      .insert({
        authid: authId,
        startup_id: startupId,
        title: `Chat - ${startup.startupName}`
      })
      .select('id')
      .single();

    if (chatError || !newChat) {
      throw new Error('Failed to create chat session: ' + (chatError?.message ?? ''));
    }
    resolvedChatId = newChat.id;
  }

  // 3. Fetch past messages for context
  const { data: pastMessages, error: messagesError } = await supabaseAdmin
    .from('messages')
    .select('sender, content, created_at')
    .eq('chat_id', resolvedChatId)
    .order('created_at', { ascending: true })
    .limit(20);

  if (messagesError) {
    throw new Error('Failed to load chat history: ' + messagesError.message);
  }

  // 4. Build prompt messages
  const promptMessages = [];

  // System context
  promptMessages.push(
    new SystemMessage(
      `You are the AI Co-Founder for the startup "${startup.startupName}".
Description of "${startup.startupName}":
${startup.description}

As a co-founder, your goal is to help build, launch, and grow the company. Be direct, action-oriented, strategic, and practical. Do not speak in corporate platitudes. Give realistic business advice.
Use clear Markdown formatting with headings, bullets, and numbered steps when helpful.
Preserve startup memory and build on top of what you discussed earlier.`
    )
  );

  // Conversation history
  for (const msg of pastMessages ?? []) {
    if (msg.sender === 'user') {
      promptMessages.push(new HumanMessage(msg.content));
    } else {
      promptMessages.push(new AIMessage(msg.content));
    }
  }

  // User's current message
  promptMessages.push(new HumanMessage(message.trim()));

  // 5. Call LLM
  const model = createChatModel({ temperature: 0.7 });
  const response = await model.invoke(promptMessages);

  const aiText = typeof response.text === 'string'
    ? response.text.trim()
    : String(response.content ?? '').trim();

  // 6. Save User message and AI response in transactions
  const { error: userMsgError } = await supabaseAdmin
    .from('messages')
    .insert({
      chat_id: resolvedChatId,
      sender: 'user',
      content: message.trim()
    });

  if (userMsgError) {
    throw new Error('Failed to save user message: ' + userMsgError.message);
  }

  const { error: aiMsgError } = await supabaseAdmin
    .from('messages')
    .insert({
      chat_id: resolvedChatId,
      sender: 'ai',
      content: aiText
    });

  if (aiMsgError) {
    throw new Error('Failed to save AI message: ' + aiMsgError.message);
  }

  return {
    chatId: resolvedChatId,
    message: aiText,
  };
}

export { handleChat };
