import { Router } from 'express';
import { z } from 'zod';
import { validateStartupFromPrompt, ValidatorError } from '../middleware/ai/validator.js';
import { generateBlueprint } from '../middleware/ai/blueprint.js';
import { generateRoadmap } from '../middleware/ai/roadmap.js';
import { handleChat } from '../middleware/ai/chat.js';
import { generateDocument } from '../middleware/ai/document.js';

const router = Router();

// Zod schemas for validation
const AuthIdSchema = z.string().uuid({ message: 'authId must be a valid UUID' });
const StartupIdSchema = z.union([z.number(), z.string().transform(val => Number(val))]).pipe(z.number().positive());

const ValidateIdeaBodySchema = z
  .object({
    prompt: z.string().min(1),
    authId: z.string().min(1).optional(),
    authid: z.string().min(1).optional(),
  })
  .strict();

const GenerateBlueprintSchema = z.object({
  authId: AuthIdSchema,
  startupId: StartupIdSchema,
}).strict();

const GenerateRoadmapSchema = z.object({
  authId: AuthIdSchema,
  startupId: StartupIdSchema,
  stage: z.enum(['idea', 'mvp', 'growth']),
}).strict();

const ChatSchema = z.object({
  authId: z.string().uuid({ message: 'authId must be a valid UUID' }).optional(),
  startupId: StartupIdSchema,
  chatId: z.string().uuid({ message: 'chatId must be a valid UUID' }).nullable().optional(),
  message: z.string().min(1),
  // Support legacy authid field
  authid: z.string().uuid({ message: 'authid must be a valid UUID' }).optional(),
}).strict();

const GenerateDocumentSchema = z.object({
  authId: AuthIdSchema,
  startupId: StartupIdSchema,
  type: z.enum([
    'pitch_deck',
    'business_plan',
    'problem_solution',
    'model_canvas',
    'validation_report',
    'user_persona',
    'gtm_strategy'
  ]),
}).strict();

// Helper to standardise error responses
function handleError(res, error, defaultMessage = 'An error occurred') {
  console.error(error);
  const status = error.statusCode ?? 500;
  return res.status(status).json({
    ok: false,
    error: {
      code: error.code ?? 'SERVER_ERROR',
      message: error.message ?? defaultMessage,
    },
  });
}

// 1. Idea validation route
router.post('/validate-idea', async (req, res) => {
  try {
    const parsed = ValidateIdeaBodySchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        ok: false,
        error: {
          code: 'INVALID_INPUT',
          message: 'Invalid request body',
          details: parsed.error.flatten(),
        },
      });
    }

    const { prompt, authId, authid } = parsed.data;
    const resolvedAuthId = authId ?? authid;

    if (!resolvedAuthId) {
      return res.status(400).json({
        ok: false,
        error: {
          code: 'INVALID_INPUT',
          message: 'authId is required',
        },
      });
    }

    const result = await validateStartupFromPrompt({
      prompt,
      authId: resolvedAuthId,
    });

    return res.status(200).json({ ok: true, data: result });
  } catch (error) {
    if (error instanceof ValidatorError) {
      return res.status(error.statusCode ?? 400).json({
        ok: false,
        error: {
          code: error.code ?? 'VALIDATION_ERROR',
          message: error.message ?? 'Validation failed',
        },
      });
    }
    return handleError(res, error, 'Unexpected server error during validation');
  }
});

// 2. Blueprint generation route
router.post('/generate-blueprint', async (req, res) => {
  try {
    const parsed = GenerateBlueprintSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        ok: false,
        error: {
          code: 'INVALID_INPUT',
          message: 'Invalid request body',
          details: parsed.error.flatten(),
        },
      });
    }

    const { authId, startupId } = parsed.data;
    const result = await generateBlueprint({ authId, startupId });

    return res.status(200).json({ ok: true, data: result });
  } catch (error) {
    return handleError(res, error, 'Failed to generate startup blueprint');
  }
});

// 3. Roadmap generation route
router.post('/generate-roadmap', async (req, res) => {
  try {
    const parsed = GenerateRoadmapSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        ok: false,
        error: {
          code: 'INVALID_INPUT',
          message: 'Invalid request body',
          details: parsed.error.flatten(),
        },
      });
    }

    const { authId, startupId, stage } = parsed.data;
    const result = await generateRoadmap({ authId, startupId, stage });

    return res.status(200).json({ ok: true, data: result });
  } catch (error) {
    return handleError(res, error, 'Failed to generate execution roadmap');
  }
});

  // 4. Co-Founder Chat route
  router.post('/chat', async (req, res) => {
    try {
      const parsed = ChatSchema.safeParse(req.body);
      if (!parsed.success) {
        return res.status(400).json({
          ok: false,
          error: {
            code: 'INVALID_INPUT',
            message: 'Invalid request body',
            details: parsed.error.flatten(),
          },
        });
      }

      const { authId, startupId, chatId, message, authid } = parsed.data;
      const resolvedAuthId = authId ?? authid;

      if (!resolvedAuthId) {
        return res.status(400).json({
          ok: false,
          error: {
            code: 'UNAUTHORIZED',
            message: 'Authentication required',
          },
        });
      }

      const result = await handleChat({ authId: resolvedAuthId, startupId, chatId, message });

      return res.status(200).json({ ok: true, data: result });
    } catch (error) {
      return handleError(res, error, 'Failed to process chat message');
    }
  });

// 5. Document generation route
router.post('/generate-document', async (req, res) => {
  try {
    const parsed = GenerateDocumentSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        ok: false,
        error: {
          code: 'INVALID_INPUT',
          message: 'Invalid request body',
          details: parsed.error.flatten(),
        },
      });
    }

    const { authId, startupId, type } = parsed.data;
    const result = await generateDocument({ authId, startupId, type });

    return res.status(200).json({ ok: true, data: result });
  } catch (error) {
    return handleError(res, error, 'Failed to generate document');
  }
});

export default router;