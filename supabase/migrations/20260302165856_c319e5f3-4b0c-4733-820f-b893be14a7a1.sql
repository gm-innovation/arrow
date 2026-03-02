
-- 1. Feed Discussions
CREATE TABLE public.corp_feed_discussions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  content text,
  pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.corp_feed_discussion_replies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id uuid NOT NULL REFERENCES public.corp_feed_discussions(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.corp_feed_discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_feed_discussion_replies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Same company can read discussions" ON public.corp_feed_discussions
  FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Authenticated can create discussions" ON public.corp_feed_discussions
  FOR INSERT TO authenticated
  WITH CHECK (author_id = auth.uid() AND company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Author can update discussions" ON public.corp_feed_discussions
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid());

CREATE POLICY "Author can delete discussions" ON public.corp_feed_discussions
  FOR DELETE TO authenticated
  USING (author_id = auth.uid());

CREATE POLICY "Same company can read replies" ON public.corp_feed_discussion_replies
  FOR SELECT TO authenticated
  USING (discussion_id IN (SELECT id FROM public.corp_feed_discussions WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));

CREATE POLICY "Authenticated can create replies" ON public.corp_feed_discussion_replies
  FOR INSERT TO authenticated
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Author can delete replies" ON public.corp_feed_discussion_replies
  FOR DELETE TO authenticated
  USING (author_id = auth.uid());

-- 2. Alter corp_feed_likes: add reaction_type
ALTER TABLE public.corp_feed_likes ADD COLUMN reaction_type text NOT NULL DEFAULT 'like';

-- Drop old unique constraint and create new one (one reaction per user per post)
DO $$
BEGIN
  -- Drop existing unique constraints on (post_id, user_id)
  PERFORM 1 FROM pg_constraint WHERE conrelid = 'public.corp_feed_likes'::regclass AND contype = 'u';
  IF FOUND THEN
    EXECUTE (
      SELECT 'ALTER TABLE public.corp_feed_likes DROP CONSTRAINT ' || conname
      FROM pg_constraint
      WHERE conrelid = 'public.corp_feed_likes'::regclass AND contype = 'u'
      LIMIT 1
    );
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS corp_feed_likes_post_user_unique ON public.corp_feed_likes(post_id, user_id);

-- 3. Polls
CREATE TABLE public.corp_feed_polls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.corp_feed_posts(id) ON DELETE CASCADE,
  question text NOT NULL,
  allow_multiple boolean NOT NULL DEFAULT false,
  ends_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.corp_feed_poll_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL REFERENCES public.corp_feed_polls(id) ON DELETE CASCADE,
  option_text text NOT NULL,
  position int NOT NULL DEFAULT 0
);

CREATE TABLE public.corp_feed_poll_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  option_id uuid NOT NULL REFERENCES public.corp_feed_poll_options(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.corp_feed_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_feed_poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_feed_poll_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read polls" ON public.corp_feed_polls FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated can insert polls" ON public.corp_feed_polls FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated can read poll options" ON public.corp_feed_poll_options FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated can insert poll options" ON public.corp_feed_poll_options FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated can read poll votes" ON public.corp_feed_poll_votes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can vote" ON public.corp_feed_poll_votes FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can remove vote" ON public.corp_feed_poll_votes FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Unique constraint: one vote per user per poll (enforced via unique on option_id + user_id per poll)
CREATE UNIQUE INDEX corp_feed_poll_votes_user_option ON public.corp_feed_poll_votes(option_id, user_id);

-- 4. Kudos
CREATE TABLE public.corp_kudos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  from_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  to_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category text NOT NULL DEFAULT 'teamwork',
  message text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.corp_kudos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Same company can read kudos" ON public.corp_kudos
  FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Authenticated can create kudos" ON public.corp_kudos
  FOR INSERT TO authenticated
  WITH CHECK (from_user_id = auth.uid() AND company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
