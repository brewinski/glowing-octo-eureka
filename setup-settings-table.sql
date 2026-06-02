-- 1. Create the settings table
CREATE TABLE settings (
  id text PRIMARY KEY,
  weights jsonb NOT NULL
);

-- 2. Insert the default global weights
INSERT INTO settings (id, weights) 
VALUES ('global', '{"pe": 0.5, "re": 0.25, "cm": 0.25, "pg": 0.5, "gs": 0.5}'::jsonb);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- 4. Create an RLS policy to allow anyone to read and write (Since this is a PoC)
-- If you are using Supabase Auth later, change 'anon' to 'authenticated'
CREATE POLICY "Enable read access for all users" ON "public"."settings"
AS PERMISSIVE FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable insert for all users" ON "public"."settings"
AS PERMISSIVE FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Enable update for all users" ON "public"."settings"
AS PERMISSIVE FOR UPDATE
TO public
USING (true)
WITH CHECK (true);
