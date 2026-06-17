-- 1. Create notion_integrations table for Notion oauth integration
CREATE TABLE IF NOT EXISTS public.notion_integrations (
  auth_id UUID PRIMARY KEY REFERENCES public.users(auth_id) ON DELETE CASCADE,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  bot_id TEXT,
  workspace_id TEXT,
  workspace_name TEXT,
  workspace_icon TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on notion_integrations
ALTER TABLE public.notion_integrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own notion integration" ON public.notion_integrations
  FOR ALL TO authenticated USING (auth_id = auth.uid()) WITH CHECK (auth_id = auth.uid());

-- 2. Create tasks table for execution roadmap
CREATE TABLE IF NOT EXISTS public.tasks (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  authid UUID NOT NULL REFERENCES public.users(auth_id) ON DELETE CASCADE,
  startup_id BIGINT NOT NULL REFERENCES public.startup(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  status TEXT DEFAULT 'todo' NOT NULL, -- 'todo', 'in_progress', 'done'
  stage TEXT DEFAULT 'idea' NOT NULL,  -- 'idea', 'mvp', 'growth'
  priority TEXT DEFAULT 'medium' NOT NULL -- 'low', 'medium', 'high'
);

-- Enable RLS on tasks
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own tasks" ON public.tasks
  FOR ALL TO authenticated USING (authid = auth.uid()) WITH CHECK (authid = auth.uid());

-- 3. Create documents table for blueprint and generated documents
CREATE TABLE IF NOT EXISTS public.documents (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  authid UUID NOT NULL REFERENCES public.users(auth_id) ON DELETE CASCADE,
  startup_id BIGINT NOT NULL REFERENCES public.startup(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  type TEXT NOT NULL, -- 'pitch_deck', 'business_plan', 'problem_solution', 'model_canvas', 'validation_report', 'user_persona', 'gtm_strategy', 'blueprint'
  content TEXT, -- markdown text
  file_url TEXT -- URL to PDF in storage
);

-- Enable RLS on documents
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own documents" ON public.documents
  FOR ALL TO authenticated USING (authid = auth.uid()) WITH CHECK (authid = auth.uid());

-- 4. Create chats table for AI Co-founder sessions
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  authid UUID NOT NULL REFERENCES public.users(auth_id) ON DELETE CASCADE,
  startup_id BIGINT NOT NULL REFERENCES public.startup(id) ON DELETE CASCADE,
  title TEXT NOT NULL
);

-- Enable RLS on chats
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own chats" ON public.chats
  FOR ALL TO authenticated USING (authid = auth.uid()) WITH CHECK (authid = auth.uid());

-- 5. Create messages table for chat messages
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  sender TEXT NOT NULL, -- 'user', 'ai'
  content TEXT NOT NULL
);

-- Enable RLS on messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own messages" ON public.messages
  FOR ALL TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.chats 
      WHERE chats.id = messages.chat_id AND chats.authid = auth.uid()
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.chats 
      WHERE chats.id = messages.chat_id AND chats.authid = auth.uid()
    )
  );

-- Grants
GRANT ALL ON TABLE public.notion_integrations TO postgres;
GRANT ALL ON TABLE public.notion_integrations TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.notion_integrations TO authenticated;

GRANT ALL ON TABLE public.tasks TO postgres;
GRANT ALL ON TABLE public.tasks TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.tasks TO authenticated;

GRANT ALL ON TABLE public.documents TO postgres;
GRANT ALL ON TABLE public.documents TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.documents TO authenticated;

GRANT ALL ON TABLE public.chats TO postgres;
GRANT ALL ON TABLE public.chats TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.chats TO authenticated;

GRANT ALL ON TABLE public.messages TO postgres;
GRANT ALL ON TABLE public.messages TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.messages TO authenticated;

-- Grant usage on sequences for primary keys
GRANT USAGE, SELECT ON SEQUENCE public.tasks_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.documents_id_seq TO authenticated;
