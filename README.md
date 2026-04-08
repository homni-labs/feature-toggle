<div align="center">
<img src="assets/feature_toggle_logo.jpeg" width="600" alt="Feature Toggle">

# Homni Feature Toggle

Self-hosted feature toggle platform with per-project RBAC, multi-environment control, and API key authentication.

[![Backend Build](https://github.com/homni-labs/feature-toggle/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/homni-labs/feature-toggle/actions/workflows/docker-publish.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## Quick Start

```bash
docker compose up -d
```

Starts PostgreSQL + Keycloak + Backend. Then run the frontend:

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | [localhost:3000](http://localhost:3000) | `admin` / `admin` |
| Backend API | [localhost:8080](http://localhost:8080) | Bearer JWT |
| Keycloak | [localhost:8180](http://localhost:8180) | `admin` / `admin` |
| Swagger UI | [localhost:8080/docs](http://localhost:8080/docs) | — |

---

## Repository Structure

```
├── backend/         Spring Boot API (Java 21)
├── frontend/        Flutter Web dashboard (Dart)
├── keycloak/        Realm config + login theme
└── docker-compose.yml
```

| Component | Details |
|-----------|---------|
| **[Backend](backend/)** | Spring Boot 3.4, PostgreSQL, Hexagonal Architecture, OpenAPI 3.0 |
| **[Frontend](frontend/)** | Flutter 3.x, BLoC/Cubit, Clean Architecture, OIDC/PKCE |
| **Keycloak** | Pre-configured realm with users, roles, and OAuth client |

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Project** | Isolated workspace with its own toggles, environments, and members |
| **Toggle** | Feature flag bound to one or more environments, can be enabled/disabled |
| **Environment** | Custom deployment target per project — not limited to DEV/STAGING/PROD |
| **Member** | User with a role (Admin, Editor, Reader) within a project |
| **API Key** | Read-only token for SDK/machine access, scoped to a project |

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

---

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `homni_feature_toggle` | Database name |
| `DB_USER` | `homni` | Database user |
| `DB_PASSWORD` | `homni` | Database password |
| `OIDC_ISSUER_URI` | `http://localhost:8180/realms/feature-toggle` | OIDC issuer URI |
| `OIDC_ADMIN_EMAIL` | `admin@homni.local` | First admin email (bootstrapped on first login) |
| `CORS_ORIGINS` | `http://localhost:3000` | Allowed CORS origins |

---

## Roadmap

- [ ] Java SDK — native client library
- [ ] Audit log — track all user and SDK actions
- [ ] Toggle dependency graphs
- [ ] Webhooks — notify external systems on toggle state changes
- [ ] Scheduled toggles — auto-enable/disable at a specific time
- [ ] Stale toggle detection
- [ ] Metrics dashboard
- [ ] Python & Go SDKs

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

Please [open an issue](https://github.com/homni-labs/feature-toggle/issues) first for major changes.

**Security** — report vulnerabilities directly via [Telegram](https://t.me/zaytsev_dv) or zaytsev.dmitry9228@gmail.com. Do not use public issues.

---

## License

[MIT](LICENSE)

<p align="center"><a href="https://github.com/homni-labs">Homni Labs</a></p>
