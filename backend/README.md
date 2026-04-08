<div align="center">
<img src="assets/feature_toggle_logo_spring.jpeg" width="600" alt="Feature Toggle Logo">

# Homni Feature Toggle Backend

[![Build](https://github.com/homni-labs/feature-toggle-backend-spring/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/homni-labs/feature-toggle-backend-spring/actions/workflows/docker-publish.yml)
[![GitHub Release](https://img.shields.io/github/v/release/homni-labs/feature-toggle-backend-spring)](https://github.com/homni-labs/feature-toggle-backend-spring/releases)
[![Pre-release](https://img.shields.io/github/v/release/homni-labs/feature-toggle-backend-spring?include_prereleases&label=pre-release)](https://github.com/homni-labs/feature-toggle-backend-spring/releases)

> Self-hosted feature toggle platform with per-project RBAC, multi-environment control, and API key authentication.

**[Russian documentation](README_RU.md)**
---
</div>

## Why Homni?

Most feature toggle solutions are either SaaS-only or lack proper access control. Homni gives you:

- **Full ownership** &mdash; deploy on your infrastructure, your rules
- **Per-project isolation** &mdash; each project has its own toggles, environments, and team members
- **Granular RBAC** &mdash; Admin / Editor / Reader roles at project level + platform-wide admins
- **Environment-aware toggles** &mdash; enable a feature in STAGING without touching PROD
- **Machine-to-machine access** &mdash; scoped API keys with expiration for SDKs and CI/CD
- **Contract-first API** &mdash; OpenAPI 3.0 spec with generated clients and Swagger UI

---

## Quick Start

### Docker Compose

```bash
  docker compose up -d
```

Starts PostgreSQL + Keycloak + App. Open Swagger UI at [localhost:8080/docs](http://localhost:8080/docs).

> The [`keycloak/`](keycloak/) directory contains a sample realm config ([`feature-toggle-realm.json`](keycloak/feature-toggle-realm.json)) and a custom login theme ([`themes/`](keycloak/themes/)).

### Docker Hub

```bash
  docker pull zaytsevdv/homni-feature-toggle:latest   # or any specific tag
```

### From source

```bash
  mvn spring-boot:run
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Project** | Isolated workspace with its own toggles, environments, and members |
| **Toggle** | Feature flag bound to one or more environments, can be enabled/disabled |
| **Environment** | Fully customizable deployment target &mdash; create, rename, or delete any environment per project (not limited to DEV/STAGING/PROD) |
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

> **Platform Admin** has unrestricted access to all projects. Other roles are scoped per project. **API Key** grants read-only access for SDK / machine integration.

---

## API

Authentication: **Bearer JWT** (OIDC) or **`X-API-Key`** header.

Full contract: [`api.yaml`](src/main/resources/openapi/api.yaml) &middot; Interactive docs available at `/docs` (Swagger UI) when the application is running.

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
| `CORS_ORIGINS` | `http://localhost:3000` | Allowed CORS origins (`*` to allow all) |

---

## Architecture

Hexagonal Architecture (Ports & Adapters) with strict DDD.

```
domain/           Pure Java: aggregates, value objects, domain exceptions
application/      Use-cases (one class = one operation) + port interfaces
infrastructure/   Spring, JDBC adapters, REST controllers, security
```

**`infrastructure` &rarr; `application` &rarr; `domain`** &mdash; the domain knows nothing about Spring, databases, or HTTP.

| Decision | Rationale |
|----------|-----------|
| No Hibernate/JPA | Native SQL via `JdbcClient` &mdash; full control, no magic |
| No Lombok | Explicit constructors, `public final` fields for value objects |
| Always Valid | Domain objects validate invariants in constructors |
| Composition Root | Use-cases wired via `@Configuration`, not `@Service` |

---

## Tech Stack

| | Technology |
|-|-----------|
| Runtime | Java 21, Spring Boot 3.4 |
| Database | PostgreSQL 17, Liquibase |
| Security | Spring Security, OAuth2 Resource Server (JWT) |
| Auth Provider | Keycloak (or any OIDC provider) |
| API | OpenAPI 3.0, code-generated controllers |
| CI/CD | GitHub Actions &rarr; Docker Hub |

---

## Roadmap

- [ ] Web UI &mdash; full-featured frontend for toggle management
- [ ] Java SDK &mdash; native client library, zero dependencies
- [ ] Quarkus backend &mdash; alternative lightweight runtime
- [ ] Audit log &mdash; track all user and SDK actions
- [ ] Toggle dependency graphs &mdash; visualize relationships between toggles
- [ ] Webhooks &mdash; notify external systems on toggle state changes
- [ ] Scheduled toggles &mdash; auto-enable/disable at a specific date and time
- [ ] Stale toggle detection &mdash; find toggles that haven't changed in N days
- [ ] Metrics dashboard &mdash; toggle evaluation stats, SDK usage, latency
- [ ] Python & Go SDKs &mdash; multi-language client support

---

## Contributing

Contributions are welcome! Whether it's a bug report, feature request, or pull request &mdash; all input is valued.

1. Fork the repo
2. Create your branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes
4. Push and open a Pull Request

Please open an [issue](https://github.com/homni-labs/feature-toggle-backend-spring/issues) first for major changes to discuss what you'd like to improve.

---

## Security

If you discover a security vulnerability, please **do not** open a public issue. Instead, reach out directly via [Telegram](https://t.me/zaytsev_dv) or email at zaytsev.dmitry9228@gmail.com.

---

## Contact

| Channel | Link |
|---------|------|
| GitHub Discussions | [discussions](https://github.com/homni-labs/feature-toggle-backend-spring/discussions) |
| Telegram | [@zaytsev_dv](https://t.me/zaytsev_dv) |
| Email | zaytsev.dmitry9228@gmail.com |

## License

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">Made with care by <a href="https://github.com/homni-labs">Homni Labs</a></p>
