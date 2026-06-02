-- 1. Create the new relational tables for the sandbox
CREATE TABLE categories_rel (
    id text PRIMARY KEY,
    label text NOT NULL,
    type text NOT NULL CHECK (type IN ('effort', 'reward')),
    weight integer NOT NULL
);

CREATE TABLE initiatives_rel (
    id text PRIMARY KEY,
    name text NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

CREATE TABLE scores_rel (
    initiative_id text REFERENCES initiatives_rel(id) ON DELETE CASCADE,
    category_id text REFERENCES categories_rel(id) ON DELETE CASCADE,
    score integer NOT NULL CHECK (score >= 0 AND score <= 10),
    PRIMARY KEY (initiative_id, category_id)
);

-- 2. Populate the categories based on the current matrix configuration
INSERT INTO categories_rel (id, label, type, weight) VALUES
('pe', 'Product engineering', 'effort', 50),
('re', 'Research', 'effort', 25),
('cm', 'Content / Marketing', 'effort', 25),
('pg', 'SEO Growth Score', 'reward', 50),
('gs', 'Commercial Growth Score', 'reward', 50);

-- 3. Safely copy over the existing initiatives
INSERT INTO initiatives_rel (id, name, updated_at)
SELECT id, name, now() FROM initiatives;

-- 4. Normalize and migrate the existing hardcoded scores into the new relational table
INSERT INTO scores_rel (initiative_id, category_id, score)
SELECT id, 'pe', COALESCE(pe, 5) FROM initiatives UNION ALL
SELECT id, 're', COALESCE(re, 5) FROM initiatives UNION ALL
SELECT id, 'cm', COALESCE(cm, 5) FROM initiatives UNION ALL
SELECT id, 'pg', COALESCE(pg, 5) FROM initiatives UNION ALL
SELECT id, 'gs', COALESCE(gs, 5) FROM initiatives;

-- 5. Enable Row Level Security (RLS) and setup open access for the PoC
ALTER TABLE categories_rel ENABLE ROW LEVEL SECURITY;
ALTER TABLE initiatives_rel ENABLE ROW LEVEL SECURITY;
ALTER TABLE scores_rel ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all" ON categories_rel FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON initiatives_rel FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON scores_rel FOR ALL USING (true) WITH CHECK (true);
