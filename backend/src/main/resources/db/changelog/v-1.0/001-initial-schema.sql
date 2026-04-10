-- ═══════════════════════════════════════════════════════════════
-- Homni Feature Toggle — full database schema (single migration)
-- ═══════════════════════════════════════════════════════════════

-- ── Projects ──────────────────────────────────────────────────

CREATE TABLE project (
    id          UUID           PRIMARY KEY,
    slug        VARCHAR(100)   NOT NULL UNIQUE,
    name        VARCHAR(255)   NOT NULL,
    description VARCHAR(1000),
    archived    BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ
);

-- ── Users ─────────────────────────────────────────────────────

CREATE TABLE app_user (
    id            UUID         PRIMARY KEY,
    oidc_subject  VARCHAR(255) UNIQUE,
    email         VARCHAR(255) NOT NULL,
    name          VARCHAR(255),
    platform_role VARCHAR(50)  NOT NULL DEFAULT 'USER',
    active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ
);

CREATE INDEX idx_app_user_oidc_subject ON app_user (oidc_subject);
CREATE UNIQUE INDEX idx_app_user_email ON app_user (email);

-- ── Project membership ────────────────────────────────────────

CREATE TABLE project_membership (
    id          UUID         PRIMARY KEY,
    project_id  UUID         NOT NULL REFERENCES project(id),
    user_id     UUID         NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    role        VARCHAR(50)  NOT NULL,
    granted_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ,
    CONSTRAINT uq_membership UNIQUE (project_id, user_id)
);

CREATE INDEX idx_membership_user ON project_membership (user_id);

-- ── Environments ──────────────────────────────────────────────

CREATE TABLE environment (
    id         UUID         PRIMARY KEY,
    project_id UUID         NOT NULL REFERENCES project(id),
    name       VARCHAR(50)  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_environment_project_name ON environment (project_id, name);

-- ── Feature toggles ───────────────────────────────────────────

CREATE TABLE feature_toggle (
    id          UUID           PRIMARY KEY,
    project_id  UUID           NOT NULL REFERENCES project(id),
    name        VARCHAR(255)   NOT NULL,
    description VARCHAR(1000),
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ
);

CREATE INDEX idx_toggle_project ON feature_toggle (project_id);
CREATE UNIQUE INDEX uq_toggle_project_name ON feature_toggle (project_id, name);

-- ── Toggle ↔ Environment (per-env on/off state) ──────────────

CREATE TABLE toggle_environment (
    toggle_id      UUID    NOT NULL REFERENCES feature_toggle(id) ON DELETE CASCADE,
    environment_id UUID    NOT NULL REFERENCES environment(id) ON DELETE RESTRICT,
    enabled        BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (toggle_id, environment_id)
);

CREATE INDEX idx_toggle_env_environment_id ON toggle_environment (environment_id);
CREATE INDEX idx_toggle_env_enabled        ON toggle_environment (toggle_id, enabled);

-- ── API keys ──────────────────────────────────────────────────

CREATE TABLE api_key (
    id           UUID         PRIMARY KEY,
    project_id   UUID         NOT NULL REFERENCES project(id),
    project_role VARCHAR(50)  NOT NULL DEFAULT 'READER',
    name         VARCHAR(255) NOT NULL,
    token_hash   VARCHAR(64)  NOT NULL UNIQUE,
    active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at   TIMESTAMPTZ
);

CREATE INDEX idx_api_key_hash_active ON api_key (token_hash) WHERE active = true;
CREATE INDEX idx_api_key_project     ON api_key (project_id);
CREATE INDEX idx_api_key_created_at  ON api_key (created_at DESC);
