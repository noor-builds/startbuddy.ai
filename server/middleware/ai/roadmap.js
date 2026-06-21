import { z } from 'zod';
import { createChatModel } from './llm.js';
import { supabaseAdmin } from '../../db.js';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';

const RoadmapTaskSchema = z.object({
  title: z.string().min(3).max(200).describe('A concrete, actionable task for the founder'),
  priority: z.enum(['low', 'medium', 'high']).describe('The priority of the task'),
});

const RoadmapSchema = z.object({
  tasks: z.array(RoadmapTaskSchema).min(3).max(10).describe('List of tasks generated for this startup stage'),
});

function contentToText(response) {
  if (typeof response === 'string') return response.trim();
  if (response && typeof response.text === 'string') return response.text.trim();
  if (response && typeof response.content === 'string') return response.content.trim();
  if (response && Array.isArray(response.content)) {
    return response.content
      .map((part) => (typeof part === 'string' ? part : part.text ?? ''))
      .join('\n')
      .trim();
  }
  return '';
}

function unwrapStructuredResponse(response) {
  if (Array.isArray(response)) {
    return response.find((item) => item && typeof item === 'object') ?? response[0];
  }

  if (typeof response === 'string') {
    return response;
  }

  if (response && typeof response === 'object') {
    if (response.output && (response.output.tasks || typeof response.output === 'string')) {
      return response.output;
    }
    if (response.data && (response.data.tasks || typeof response.data === 'string')) {
      return response.data;
    }
  }

  return response;
}

function parseJsonFromText(text) {
  const cleaned = text
    .replace(/```json\s*/i, '')
    .replace(/```\s*$/, '')
    .trim();

  try {
    return JSON.parse(cleaned);
  } catch (error) {
    const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw error;
    return JSON.parse(jsonMatch[0]);
  }
}

function parseRoadmapResponse(response) {
  const unwrapped = unwrapStructuredResponse(response);

  if (unwrapped && typeof unwrapped === 'object' && !Array.isArray(unwrapped)) {
    return RoadmapSchema.parse(unwrapped).tasks;
  }

  const text = contentToText(unwrapped);
  if (!text) throw new Error('AI returned an empty roadmap response');

  try {
    return RoadmapSchema.parse(parseJsonFromText(text)).tasks;
  } catch (jsonError) {
    const parsedLines = parseMarkdownTasks(text);
    if (parsedLines.length >= 3) return parsedLines;
    throw jsonError;
  }
}

function parseMarkdownTasks(text) {
  const lines = text
    .replace(/```/g, '\n')
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => /^(\d+\.|-|\*|\+)\s+/.test(line));

  return lines
    .map((line) => {
      const withoutMarker = line.replace(/^(\d+\.|-|\*|\+)\s+/, '').trim();
      const priorityMatch = withoutMarker.match(/\b(low|medium|high)\b/i);
      const priority = priorityMatch ? priorityMatch[1].toLowerCase() : 'medium';
      const title = withoutMarker.replace(/\b(low|medium|high)\b/i, '').replace(/\s+/g, ' ').trim();

      return { title, priority };
    })
    .filter((task) => task.title.length >= 3 && task.title.length <= 200)
    .slice(0, 10);
}

async function generateRoadmapTasks({ startup, cleanStage }) {
  const model = createChatModel({ temperature: 0.3 });

  try {
    const structuredNamer = model.withStructuredOutput(RoadmapSchema, {
      name: 'generate_roadmap_tasks',
    });

    const structuredResponse = await structuredNamer.invoke([
      new SystemMessage(
        `You are an expert startup advisor and incubator manager.
Return only JSON matching this schema:
{
  "tasks": [
    { "title": "concrete action item", "priority": "low|medium|high" }
  ]
}

Rules:
- Return 5-8 tasks.
- Tasks must be relevant to the startup stage:
  * idea: market research, user interviews, validation, landing page setup, value prop refinement.
  * mvp: defining core features, architecture design, front-end/back-end setup, user testing.
  * growth: marketing campaigns, SEO, referral loops, scaling infrastructure, analytical tracking.
- Output tasks that are highly customized to the startup's name and description.
- Do not include markdown, explanations, or code fences.`
      ),
      new HumanMessage(
        `Startup Name: ${startup.startupName}\nDescription: ${startup.description}\nCurrent Stage: ${cleanStage.toUpperCase()}`
      ),
    ]);

    return parseRoadmapResponse(structuredResponse);
  } catch (structuredError) {
    const response = await model.invoke([
      new SystemMessage(
        `You are an expert startup advisor and incubator manager.
Return only a JSON object with a "tasks" array.
Each task must have:
- title: a concrete action item, 3-200 characters.
- priority: "low", "medium", or "high".

Return 5-8 tasks. No markdown. No code fences. No extra text.`
      ),
      new HumanMessage(
        `Startup Name: ${startup.startupName}\nDescription: ${startup.description}\nCurrent Stage: ${cleanStage.toUpperCase()}`
      ),
    ]);

    return parseRoadmapResponse(response);
  }
}

async function generateRoadmap({ authId, startupId, stage }) {
  const validStages = ['idea', 'mvp', 'growth'];
  const cleanStage = String(stage).toLowerCase().trim();
  if (!validStages.includes(cleanStage)) {
    throw new Error(`Invalid stage: ${stage}. Must be one of: ${validStages.join(', ')}`);
  }

  const { data: startup, error: startupError } = await supabaseAdmin
    .from('startup')
    .select('id, startupName, description')
    .eq('id', startupId)
    .eq('authid', authId)
    .single();

  if (startupError || !startup) {
    throw new Error('Startup not found: ' + (startupError?.message ?? ''));
  }

  const extractedTasks = await generateRoadmapTasks({ startup, cleanStage });

  const tasksToInsert = extractedTasks.map((t) => ({
    authid: authId,
    startup_id: startupId,
    title: t.title,
    priority: t.priority,
    stage: cleanStage,
    status: 'todo',
  }));

  const { data: insertedTasks, error: insertError } = await supabaseAdmin
    .from('tasks')
    .insert(tasksToInsert)
    .select();

  if (insertError) {
    throw new Error('Failed to insert generated tasks: ' + insertError.message);
  }

  return insertedTasks;
}

export { generateRoadmap };
