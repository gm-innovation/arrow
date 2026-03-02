
-- Storage bucket for feed media
INSERT INTO storage.buckets (id, name, public) VALUES ('corp-feed-media', 'corp-feed-media', true);

-- Storage RLS policies
CREATE POLICY "Authenticated users can upload feed media" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'corp-feed-media');
CREATE POLICY "Anyone can view feed media" ON storage.objects FOR SELECT USING (bucket_id = 'corp-feed-media');
CREATE POLICY "Users can delete own feed media" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'corp-feed-media' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Attachments table
CREATE TABLE public.corp_feed_attachments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES public.corp_feed_posts(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL DEFAULT 'file',
  file_size BIGINT,
  mime_type TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.corp_feed_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view attachments" ON public.corp_feed_attachments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Post authors can insert attachments" ON public.corp_feed_attachments FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM public.corp_feed_posts WHERE id = post_id AND author_id = auth.uid())
);
CREATE POLICY "Post authors can delete attachments" ON public.corp_feed_attachments FOR DELETE TO authenticated USING (
  EXISTS (SELECT 1 FROM public.corp_feed_posts WHERE id = post_id AND author_id = auth.uid())
);
