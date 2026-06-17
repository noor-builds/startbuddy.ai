import { supabaseAdmin } from './db.js';

async function run() {
  const tables = [
    'users',
    'startup',
    'tasks',
    'blueprints',
    'roadmaps',
    'documents',
    'chats',
    'messages',
    'notion_integrations'
  ];
  console.log('Checking tables in Supabase...');
  for (const table of tables) {
    try {
      const { data, error } = await supabaseAdmin.from(table).select('*').limit(1);
      if (error) {
        console.log(`Table "${table}": Error - ${error.message} (${error.code})`);
      } else {
        console.log(`Table "${table}": Exists!`);
        if (data && data.length > 0) {
          console.log(`  Columns: ${Object.keys(data[0]).join(', ')}`);
        } else {
          console.log(`  Columns: (exists but empty table)`);
        }
      }
    } catch (e) {
      console.log(`Table "${table}": Exception - ${e.message}`);
    }
  }
  process.exit(0);
}
run();
