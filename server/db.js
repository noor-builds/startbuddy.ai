import path from 'path';
import { fileURLToPath } from 'url';
import { createClient } from '@supabase/supabase-js';
import ws from 'ws';
import dotenv from 'dotenv';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl?.trim() || !supabaseKey?.trim()) {
  throw new Error('SUPABASE_URL and SUPABASE_KEY must be configured in server/.env');
}

const clientOptions = {
  realtime: {
    transport: ws,
  },
};

const supabase = createClient(supabaseUrl, supabaseKey, clientOptions);

if (!supabaseServiceRoleKey?.trim()) {
  throw new Error(
    'SUPABASE_SERVICE_ROLE_KEY must be configured in server/.env for admin operations.\n' +
      'Use a Supabase service role key, not the public anon key.'
  );
}

const supabaseAdmin = createClient(
  supabaseUrl,
  supabaseServiceRoleKey.trim(),
  clientOptions
);

const hasServiceRoleKey = true;

export { supabase, supabaseAdmin, hasServiceRoleKey };
