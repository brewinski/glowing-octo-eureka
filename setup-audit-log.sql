-- 1. Create the Audit Log Table
CREATE TABLE audit_log (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    table_name text NOT NULL,
    record_id text NOT NULL,
    action text NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    old_data jsonb,
    new_data jsonb,
    changed_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 2. Create the Trigger Function
CREATE OR REPLACE FUNCTION record_history()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data)
        VALUES (TG_TABLE_NAME, OLD.id, TG_OP, row_to_json(OLD)::jsonb);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Only log if something actually changed
        IF row_to_json(OLD)::jsonb != row_to_json(NEW)::jsonb THEN
            INSERT INTO audit_log (table_name, record_id, action, old_data, new_data)
            VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (table_name, record_id, action, new_data)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(NEW)::jsonb);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Attach the Trigger to the tables
-- (Note: scores_rel uses a composite primary key, so we'll cast the whole row to JSON for the record_id to keep it simple, or just use initiative_id)

-- Trigger for initiatives_rel
CREATE TRIGGER audit_initiatives_changes
AFTER INSERT OR UPDATE OR DELETE ON initiatives_rel
FOR EACH ROW EXECUTE FUNCTION record_history();

-- Trigger for categories_rel
CREATE TRIGGER audit_categories_changes
AFTER INSERT OR UPDATE OR DELETE ON categories_rel
FOR EACH ROW EXECUTE FUNCTION record_history();

-- Custom Trigger Function for scores_rel (since it has a composite primary key)
CREATE OR REPLACE FUNCTION record_scores_history()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data)
        VALUES (TG_TABLE_NAME, OLD.initiative_id || '_' || OLD.category_id, TG_OP, row_to_json(OLD)::jsonb);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF row_to_json(OLD)::jsonb != row_to_json(NEW)::jsonb THEN
            INSERT INTO audit_log (table_name, record_id, action, old_data, new_data)
            VALUES (TG_TABLE_NAME, NEW.initiative_id || '_' || NEW.category_id, TG_OP, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (table_name, record_id, action, new_data)
        VALUES (TG_TABLE_NAME, NEW.initiative_id || '_' || NEW.category_id, TG_OP, row_to_json(NEW)::jsonb);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_scores_changes
AFTER INSERT OR UPDATE OR DELETE ON scores_rel
FOR EACH ROW EXECUTE FUNCTION record_scores_history();

-- 4. Enable RLS on audit_log so it's secure
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
-- Only allow reading for admins/users, no deleting or updating logs
CREATE POLICY "Enable read access for all" ON "public"."audit_log" FOR SELECT USING (true);
