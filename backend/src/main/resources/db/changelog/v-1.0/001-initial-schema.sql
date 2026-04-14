CREATE TABLE project (
    id          UUID           PRIMARY KEY,
    slug        VARCHAR(100)   NOT NULL UNIQUE,
    name        VARCHAR(255)   NOT NULL,
    description VARCHAR(1000),
    archived    BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ
);

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

CREATE TABLE environment (
    id         UUID         PRIMARY KEY,
    project_id UUID         NOT NULL REFERENCES project(id),
    name       VARCHAR(50)  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_environment_project_name ON environment (project_id, name);

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

CREATE TABLE toggle_environment (
    toggle_id      UUID    NOT NULL REFERENCES feature_toggle(id) ON DELETE CASCADE,
    environment_id UUID    NOT NULL REFERENCES environment(id) ON DELETE RESTRICT,
    enabled        BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (toggle_id, environment_id)
);

CREATE INDEX idx_toggle_env_environment_id ON toggle_environment (environment_id);
CREATE INDEX idx_toggle_env_enabled        ON toggle_environment (toggle_id, enabled);

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

CREATE TABLE api_key_client (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    api_key_id      UUID         NOT NULL REFERENCES api_key(id) ON DELETE CASCADE,
    project_id      UUID         NOT NULL REFERENCES project(id),
    client_type     VARCHAR(20)  NOT NULL,
    sdk_name        VARCHAR(100),
    service_name    VARCHAR(255) NOT NULL,
    namespace       VARCHAR(255),
    first_seen_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    last_seen_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    request_count   BIGINT       NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX uq_api_key_client ON api_key_client (api_key_id, service_name, COALESCE(namespace, ''));
CREATE INDEX idx_akc_api_key   ON api_key_client (api_key_id);
CREATE INDEX idx_akc_project   ON api_key_client (project_id);
CREATE INDEX idx_akc_last_seen ON api_key_client (last_seen_at DESC);
