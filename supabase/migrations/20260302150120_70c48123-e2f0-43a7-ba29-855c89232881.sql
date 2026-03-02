
-- Likes table
CREATE TABLE public.corp_feed_likes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES public.corp_feed_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(post_id, user_id)
);

-- Comments table
CREATE TABLE public.corp_feed_comments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES public.corp_feed_posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.corp_feed_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_feed_comments ENABLE ROW LEVEL SECURITY;

-- RLS for likes
CREATE POLICY "Authenticated users can read likes" ON public.corp_feed_likes
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can insert own likes" ON public.corp_feed_likes
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own likes" ON public.corp_feed_likes
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- RLS for comments
CREATE POLICY "Authenticated users can read comments" ON public.corp_feed_comments
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can insert own comments" ON public.corp_feed_comments
  FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid());

CREATE POLICY "Users can delete own comments" ON public.corp_feed_comments
  FOR DELETE TO authenticated USING (author_id = auth.uid());

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.corp_feed_likes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.corp_feed_comments;
