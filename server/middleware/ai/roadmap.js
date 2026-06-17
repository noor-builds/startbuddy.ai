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

async function generateRoadmap({ authId, startupId, stage }) {
  // Validate stage
  const validStages = ['idea', 'mvp', 'growth'];
  const cleanStage = String(stage).toLowerCase().trim();
  if (!validStages.includes(cleanStage)) {
    throw new Error(`Invalid stage: ${stage}. Must be one of: ${validStages.join(', ')}`);
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

  // 2. Query Gemini with structured output
  const model = createChatModel({ temperature: 0.5 });
  const structuredNamer = model.withStructuredOutput(RoadmapSchema, {
    name: 'generate_roadmap_tasks',
  });

  const response = await structuredNamer.invoke([
    new SystemMessage(
      `You are an expert startup advisor and incubator manager.
Generate a list of 5-8 concrete, actionable next steps for a startup at the given stage.
Rules:
- Tasks must be relevant to the startup stage:
  * idea: market research, user interviews, validation, landing page setup, value prop refinement.
  * mvp: defining core features, architecture design, front-end/back-end setup, user testing.
  * growth: marketing campaigns, SEO, referral loops, scaling infrastructure, analytical tracking.
- Output tasks that are highly customized to the startup's name and description.
- Do not create generic placeholder tasks.`
    ),
    new HumanMessage(
      `Startup Name: ${startup.startupName}\nDescription: ${startup.description}\nCurrent Stage: ${cleanStage.toUpperCase()}`
    ),
  ]);

  const extractedTasks = RoadmapSchema.parse(response).tasks;

  // 3. Save tasks to the database
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
