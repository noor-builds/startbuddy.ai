import { Router } from 'express';
import { z } from 'zod';
import { validateStartupFromPrompt, ValidatorError } from '../middleware/ai/validator.js';

const router = Router();

const ValidateIdeaBodySchema = z
  .object({
    prompt: z.string().min(1),
    authId: z.string().min(1).optional(),
    // Back-compat: older clients may send authid
    authid: z.string().min(1).optional(),
  })
  .strict();

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

    console.error(error);
    return res.status(500).json({
      ok: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Unexpected server error',
      },
    });
  }
});

export default router;