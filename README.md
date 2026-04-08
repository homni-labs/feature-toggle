<div align="center">

<img src="assets/feature_toggle_logo.jpeg" width="600" alt="Homni Feature Toggle">

# Homni Feature Toggle

Self-hosted feature flag platform with per-project RBAC, multi-environment control, and API key authentication.

**[Документация на русском](README_RU.md)**

[![Build](https://github.com/homni-labs/feature-toggle/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/homni-labs/feature-toggle/actions/workflows/docker-publish.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/homni-labs/feature-toggle)](https://github.com/homni-labs/feature-toggle/releases)
[![GitHub Stars](https://img.shields.io/github/stars/homni-labs/feature-toggle?style=social)](https://github.com/homni-labs/feature-toggle)
[![Docker Pulls](https://img.shields.io/docker/pulls/zaytsevdv/homni-feature-toggle)](https://hub.docker.com/r/zaytsevdv/homni-feature-toggle)

</div>

---

## Screenshots

> Coming soon &mdash; screenshots of the dashboard, toggle management, and project settings will be added here.

---

## Why Homni?

Most feature toggle solutions are either SaaS-only or lack proper access control. Homni gives you:

- **Full ownership** &mdash; deploy on your infrastructure, no vendor lock-in, no usage limits, no data leaving your network
- **Per-project isolation** &mdash; each project has its own toggles, environments, team members, and API keys
- **Granular RBAC** &mdash; Platform Admin, Project Admin, Editor, Reader &mdash; clear permission boundaries at every level
- **Environment-aware toggles** &mdash; create custom environments per project, not limited to DEV / STAGING / PROD
- **Contract-first API** &mdash; OpenAPI 3.0 spec with code-generated controllers, Swagger UI, and scoped API keys

---

## Features

- &#x1F512; **OIDC Authentication** &mdash; Keycloak out of the box with a custom login page, compatible with any OpenID Connect provider. OAuth 2.1 + PKCE
- &#x1F4C1; **Project Isolation** &mdash; each project is a self-contained workspace with its own toggles, environments, members, and API keys
- &#x1F6E1; **Granular RBAC** &mdash; Platform Admin, Project Admin, Editor, Reader with a fine-grained permissions matrix
- &#x1F30D; **Multi-Environment Control** &mdash; create and manage custom deployment targets per project
- &#x1F511; **API Key Authentication** &mdash; scoped read-only tokens with optional expiration for CI/CD pipelines and external services
- &#x1F4D6; **OpenAPI 3.0** &mdash; full API contract with interactive Swagger UI at `/docs`
- &#x1F5A5; **Admin Dashboard** &mdash; full-featured Flutter Web UI for managing projects, toggles, environments, members, and API keys

---

## Quick Start

**1. Clone the repository**

```bash
git clone https://github.com/homni-labs/feature-toggle.git
cd feature-toggle
```

**2. Start infrastructure** (PostgreSQL + Keycloak + Backend)

```bash
docker compose up -d
```

**3. Start the frontend**

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | [localhost:3000](http://localhost:3000) | `admin` / `admin` |
| Backend API | [localhost:8080](http://localhost:8080) | Bearer JWT |
| Swagger UI | [localhost:8080/docs](http://localhost:8080/docs) | &mdash; |
| Keycloak Admin | [localhost:8180](http://localhost:8180) | `admin` / `admin` |

> Pre-configured test users: `admin` / `admin` (Platform Admin), `editor` / `editor`, `reader` / `reader`.

---

## Local Development

### Prerequisites

| Tool | Version | |
|------|---------|---|
| Java | 21+ | [adoptium.net](https://adoptium.net) |
| Maven | 3.9+ | [maven.apache.org](https://maven.apache.org) |
| Flutter | &ge; 3.2 | [flutter.dev](https://flutter.dev) |
| Docker & Compose | Latest | [docs.docker.com](https://docs.docker.com) |

### Backend

Start only the infrastructure services:

```bash
docker compose up -d postgres keycloak
```

Run the backend from source (defaults match the Compose setup, no extra configuration needed):

```bash
cd backend
mvn spring-boot:run
```

The backend starts on port **8080**. Liquibase runs migrations automatically on startup.

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

The frontend starts on port **3000**. Default config points to `localhost:8080` (API) and `localhost:8180` (Keycloak) &mdash; no extra configuration needed.

### Verify everything works

```bash
# Backend health check
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP"}
```

- Swagger UI: open [localhost:8080/docs](http://localhost:8080/docs)
- Frontend: open [localhost:3000](http://localhost:3000), log in with `admin` / `admin`

---

## Architecture

- **Backend** &mdash; Hexagonal Architecture (Ports & Adapters) with strict DDD. The domain layer has zero framework dependencies. See [backend/README.md](backend/README.md) for details.
- **Frontend** &mdash; Clean Architecture with feature-based modules (auth, projects, toggles, environments, members, API keys, users). BLoC/Cubit state management with sealed states. See [frontend/README.md](frontend/README.md) for details.

---

## API

Authentication: **Bearer JWT** (OIDC) or **`X-API-Key`** header.

Full OpenAPI 3.0 spec: [`backend/src/main/resources/openapi/api.yaml`](backend/src/main/resources/openapi/api.yaml)

Interactive Swagger UI available at [`/docs`](http://localhost:8080/docs) when the backend is running.

---

## Configuration

### Backend

All variables have sensible defaults for local development.

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `homni_feature_toggle` | Database name |
| `DB_USER` | `homni` | Database user |
| `DB_PASSWORD` | `homni` | Database password |
| `OIDC_ISSUER_URI` | `http://localhost:8180/realms/feature-toggle` | OIDC issuer URI |
| `OIDC_ADMIN_EMAIL` | `admin@homni.local` | First admin email (bootstrapped on first login) |
| `CORS_ORIGINS` | `*` | Allowed CORS origins |
| `LOG_LEVEL` | `DEBUG` | Application log level |

### Frontend

Compile-time constants passed via `--dart-define`. Defaults work out of the box for local development.

| Variable | Default | Description |
|----------|---------|-------------|
| `API_BASE_URL` | `http://localhost:8080` | Backend API URL |
| `OIDC_ISSUER` | `http://localhost:8180/realms/feature-toggle` | OIDC issuer |
| `OIDC_CLIENT_ID` | `feature-toggle-frontend` | OIDC client ID |
| `OIDC_REDIRECT_URI` | `http://localhost:3000/callback` | OIDC redirect URI |
| `OIDC_POST_LOGOUT_REDIRECT_URI` | `http://localhost:3000/` | Post-logout redirect URI |

---

## Permissions

| Action | Platform Admin | Project Admin | Editor | Reader | API Key |
|--------|:-:|:-:|:-:|:-:|:-:|
| Create / archive projects | + | | | | |
| Manage platform users | + | | | | |
| Manage members | + | + | | | |
| Manage API keys | + | + | | | |
| Manage environments | + | + | | | |
| Create / update / delete toggles | + | + | + | | |
| Enable / disable toggles | + | + | + | | |
| Read toggles | + | + | + | + | + |

> **Platform Admin** has unrestricted access to all projects. Other roles are scoped per project. **API Key** grants read-only access for machine integration.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes
4. Open a Pull Request

Please [open an issue](https://github.com/homni-labs/feature-toggle/issues) first for major changes to discuss what you'd like to improve.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

**Security** &mdash; if you discover a vulnerability, please **do not** open a public issue. Reach out directly via [Telegram](https://t.me/zaytsev_dv) or email at zaytsev.dmitry9228@gmail.com.

---

## Roadmap

- [ ] Java SDK &mdash; native client library
- [ ] Audit log &mdash; track all user actions
- [ ] Webhooks &mdash; notify external systems on toggle state changes
- [ ] Scheduled toggles &mdash; auto-enable/disable at a specific time
- [ ] Stale toggle detection &mdash; find toggles that haven't changed in N days
- [ ] Authentik support &mdash; out-of-the-box integration as an alternative OIDC provider
- [ ] Quarkus backend &mdash; alternative lightweight runtime, ready to use out of the box
- [ ] Observability &mdash; built-in metrics, tracing, and health checks for the backend
- [ ] Frontend theming &mdash; customizable colors, logo, and branding via configuration

---

## License

This project is licensed under the [MIT License](LICENSE).

<p align="center">Made with care by <a href="https://github.com/homni-labs">Homni Labs</a></p>
