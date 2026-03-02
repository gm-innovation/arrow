
-- Table: corp_group_discussions (forum topics)
CREATE TABLE public.corp_group_discussions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.corp_groups(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  content text,
  pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Table: corp_group_discussion_posts (replies)
CREATE TABLE public.corp_group_discussion_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id uuid NOT NULL REFERENCES public.corp_group_discussions(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.corp_group_discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corp_group_discussion_posts ENABLE ROW LEVEL SECURITY;

-- RLS for corp_group_discussions
CREATE POLICY "Members can view discussions"
  ON public.corp_group_discussions FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM corp_group_members cgm
    WHERE cgm.group_id = corp_group_discussions.group_id
      AND cgm.user_id = auth.uid()
  ));

CREATE POLICY "Members can create discussions"
  ON public.corp_group_discussions FOR INSERT TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM corp_group_members cgm
      WHERE cgm.group_id = corp_group_discussions.group_id
        AND cgm.user_id = auth.uid()
    )
  );

CREATE POLICY "Author can update discussions"
  ON public.corp_group_discussions FOR UPDATE TO authenticated
  USING (author_id = auth.uid());

CREATE POLICY "Author can delete discussions"
  ON public.corp_group_discussions FOR DELETE TO authenticated
  USING (author_id = auth.uid());

-- RLS for corp_group_discussion_posts
CREATE POLICY "Members can view posts"
  ON public.corp_group_discussion_posts FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM corp_group_discussions d
    JOIN corp_group_members cgm ON cgm.group_id = d.group_id
    WHERE d.id = corp_group_discussion_posts.discussion_id
      AND cgm.user_id = auth.uid()
  ));

CREATE POLICY "Members can create posts"
  ON public.corp_group_discussion_posts FOR INSERT TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM corp_group_discussions d
      JOIN corp_group_members cgm ON cgm.group_id = d.group_id
      WHERE d.id = corp_group_discussion_posts.discussion_id
        AND cgm.user_id = auth.uid()
    )
  );

CREATE POLICY "Author can delete posts"
  ON public.corp_group_discussion_posts FOR DELETE TO authenticated
  USING (author_id = auth.uid());
