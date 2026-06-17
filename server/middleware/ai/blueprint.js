import { createChatModel } from './llm.js';
import { supabaseAdmin } from '../../db.js';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';

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
  const model = createChatModel({ temperature: 0.3 });
  const response = await model.invoke([
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
  ]);

  const contentText = typeof response.text === 'string'
    ? response.text.trim()
    : String(response.content ?? '').trim();

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
