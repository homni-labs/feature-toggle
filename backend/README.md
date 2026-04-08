<div align="center">
<img src="assets/feature_toggle_logo_spring.jpeg" width="600" alt="Feature Toggle Logo">

# Homni Feature Toggle Backend

[![Build](https://github.com/homni-labs/feature-toggle/actions/workflows/ci.yml/badge.svg)](https://github.com/homni-labs/feature-toggle/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

> REST API powering Homni Feature Toggle &mdash; Spring Boot 3.4, Hexagonal Architecture, PostgreSQL, OpenAPI 3.0, OIDC + API key auth.

**[Russian documentation](README_RU.md)** &middot; **[Project README](../README.md)**

</div>

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

## Project Structure

```
src/main/java/com/homni/featuretoggle/
├── domain/
│   ├── model/          Aggregates, value objects, enums
│   └── exception/      Domain exceptions (NotFound, AccessDenied, Conflict, Validation)
├── application/
│   ├── usecase/        One class per operation (CreateToggle, ListToggles, ...)
│   └── port/out/       Repository interfaces, CallerPort, CallerProjectAccessPort
└── infrastructure/
    ├── adapter/
    │   ├── inbound/rest/         Controllers + presenters (domain → API mapping)
    │   └── outbound/persistence/ JDBC adapters (JdbcClient, raw SQL)
    ├── security/                  Auth filters, JWT converter, OIDC auto-registration
    ├── exception/                 GlobalExceptionHandler
    └── config/                    CompositionRootConfig, SecurityConfig, CORS
```

---

## Error Handling

Domain exceptions map to HTTP status codes via `GlobalExceptionHandler`:

| Exception | HTTP | Code |
|-----------|------|------|
| `DomainNotFoundException` | 404 | `NOT_FOUND` |
| `DomainAccessDeniedException` | 403 | `FORBIDDEN` |
| `DomainConflictException` | 409 | `CONFLICT` |
| `DomainValidationException` | 422 | `VALIDATION_ERROR` |

Security errors: `TOKEN_EXPIRED` (401), `UNAUTHORIZED` (401), `FORBIDDEN` (403).

All error responses follow a consistent format:

```json
{
  "payload": {
    "code": "NOT_FOUND",
    "message": "Toggle not found"
  },
  "meta": {
    "timestamp": "2026-04-09T12:00:00Z"
  }
}
```

---

## Security

Dual authentication chain:

1. **API Key Filter** &mdash; `ApiKeyAuthFilter` extracts `X-API-Key` header, hashes with SHA-256, looks up active key in DB. Sets `ApiKeyAuthentication` (project-scoped, always READER). Short-circuits if found.

2. **JWT / OIDC** &mdash; falls back to OAuth2 Resource Server. Validates JWT, extracts `sub`, `email`, `name` claims. Auto-creates user on first login via `FindOrCreateUserUseCase`. First user matching `OIDC_ADMIN_EMAIL` is promoted to Platform Admin.

3. **Domain-level authorization** &mdash; use-cases call `callerAccess.resolve(projectId).ensure(Permission.WRITE_TOGGLES)`. Platform Admins bypass project role checks.

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

<p align="center">Made with care by <a href="https://github.com/homni-labs">Homni Labs</a></p>
