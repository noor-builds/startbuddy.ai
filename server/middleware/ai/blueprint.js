import { createChatModel } from './llm.js';
import { supabaseAdmin } from '../../db.js';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';

const FALLBACK_MODEL = process.env.GEMINI_FALLBACK_MODEL ?? 'gemini-2.5-flash-lite';

function isTransientModelError(error) {
  const status = error?.status ?? error?.statusCode ?? error?.response?.status;
  const details = `${error?.code ?? ''} ${error?.message ?? ''}`;

  return status === 429 ||
    status === 503 ||
    /\b(UNAVAILABLE|RESOURCE_EXHAUSTED)\b/i.test(details);
}

async function generateBlueprint({ authId, startupId }) {
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

  // 2. Query LLM to generate the blueprint
  const messages = [
    new SystemMessage(
      `You are an expert startup strategist. Generate a comprehensive Startup Blueprint for the user's startup.
The blueprint must cover the following sections in detail:
1. Problem Statement: Explain the exact problem the startup solves.
2. Solution Description: Describe the product and how it solves the problem.
3. Target Audience: Define the primary and secondary customer segments.
4. Unique Value Proposition: Explain why this is different and better than competitors.
5. Revenue Model: Outline how the startup makes money.
6. Distribution Channels: Explain how the startup will acquire and reach customers.

Format the output in beautiful, clean Markdown with proper headings (using ## for each section) and bullet points.`
    ),
    new HumanMessage(
      `Startup Name: ${startup.startupName}\nStartup Description: ${startup.description}`
    ),
  ];

  let response;
  try {
    response = await createChatModel({ temperature: 0.3 }).invoke(messages);
  } catch (error) {
    if (!isTransientModelError(error)) throw error;

    console.warn(
      `Primary Gemini model temporarily unavailable; retrying blueprint with ${FALLBACK_MODEL}.`
    );
    response = await createChatModel({
      model: FALLBACK_MODEL,
      temperature: 0.3,
    }).invoke(messages);
  }

  const contentText = typeof response.text === 'string'
    ? response.text.trim()
    : String(response.content ?? '').trim();

  if (!contentText) {
    throw new Error('Gemini returned an empty startup blueprint.');
  }

  // 3. Save to documents table
  const { data: doc, error: docError } = await supabaseAdmin
    .from('documents')
    .insert({
      authid: authId,
      startup_id: startupId,
      title: 'Startup Blueprint',
      type: 'blueprint',
      content: contentText
    })
    .select()
    .single();

  if (docError) {
    throw new Error('Failed to save blueprint document: ' + docError.message);
  }

  return doc;
}

export { generateBlueprint };
