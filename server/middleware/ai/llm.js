import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { ChatGoogle } from '@langchain/google';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const DEFAULT_MODEL = process.env.GEMINI_MODEL ?? 'gemini-2.5-flash';
const SEARCH_MODEL = process.env.GEMINI_SEARCH_MODEL ?? DEFAULT_MODEL;

function assertApiKey() {
  const apiKey = process.env.GOOGLE_API_KEY;
  if (!apiKey?.trim()) {
    const err = new Error(
      'GOOGLE_API_KEY is not configured. Set it in server/.env or the Vercel project environment.'
    );
    err.code = 'MISSING_API_KEY';
    throw err;
  }
  return apiKey.trim();
}

/**
 * Base Gemini chat model (structured extraction, naming).
 */
function createChatModel(overrides = {}) {
  return new ChatGoogle({
    model: overrides.model ?? DEFAULT_MODEL,
    apiKey: assertApiKey(),
    temperature: overrides.temperature ?? 0.2,
    maxRetries: 2,
  });
}

/**
 * Gemini model with Google Search grounding for market research.
 */
function createSearchModel(overrides = {}) {
  return createChatModel({
    model: SEARCH_MODEL,
    ...overrides,
  }).bindTools([{ googleSearch: {} }]);
}

export { createChatModel, createSearchModel, DEFAULT_MODEL, SEARCH_MODEL };
