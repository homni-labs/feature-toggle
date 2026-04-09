ALTER TABLE toggle_environment
    ADD COLUMN enabled BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE toggle_environment te
SET enabled = ft.enabled
FROM feature_toggle ft
WHERE te.toggle_id = ft.id;

ALTER TABLE feature_toggle
    DROP COLUMN enabled;

CREATE INDEX idx_toggle_env_enabled
    ON toggle_environment (toggle_id, enabled);
