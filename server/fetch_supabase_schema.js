import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

async function run() {
  if (!supabaseUrl || !supabaseKey) {
    console.error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are not configured.');
    process.exit(1);
  }

  try {
    const url = `${supabaseUrl}/rest/v1/`;
    console.log(`Fetching OpenAPI spec from ${url}...`);
    const response = await fetch(url, {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`
      }
    });

    if (!response.ok) {
      console.error(`HTTP error: ${response.status} ${response.statusText}`);
      const body = await response.text();
      console.error(body);
      process.exit(1);
    }

    const data = await response.json();
    console.log('OpenAPI Info Title:', data.info?.title);
    console.log('\nExposed Paths (Tables/Views/RPCs):');
    const paths = Object.keys(data.paths ?? {});
    paths.forEach(p => console.log(`  ${p}`));
    
    console.log('\nDefinitions (Schemas):');
    const definitions = Object.keys(data.definitions ?? {});
    definitions.forEach(d => console.log(`  ${d}`));
  } catch (error) {
    console.error('Error fetching OpenAPI spec:', error);
  }
}
run();


