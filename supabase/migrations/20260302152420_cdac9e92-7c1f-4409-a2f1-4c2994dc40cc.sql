
-- Create corp_feed_mentions table
CREATE TABLE public.corp_feed_mentions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES public.corp_feed_posts(id) ON DELETE CASCADE,
  mention_type TEXT NOT NULL CHECK (mention_type IN ('role', 'user')),
  mention_value TEXT NOT NULL,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.corp_feed_mentions ENABLE ROW LEVEL SECURITY;

-- Read: any authenticated user
CREATE POLICY "Authenticated users can read mentions"
  ON public.corp_feed_mentions FOR SELECT
  TO authenticated
  USING (true);

-- Insert: author of the post
CREATE POLICY "Post author can insert mentions"
  ON public.corp_feed_mentions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.corp_feed_posts
      WHERE id = post_id AND author_id = auth.uid()
    )
  );

-- Delete: author of the post
CREATE POLICY "Post author can delete mentions"
  ON public.corp_feed_mentions FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.corp_feed_posts
      WHERE id = post_id AND author_id = auth.uid()
    )
  );
