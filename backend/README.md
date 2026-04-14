<div align="center">

# Homni Feature Toggle &mdash; Backend

REST API powering Homni Feature Toggle.

**[Russian documentation](README_RU.md)** &middot; **[Project README](../README.md)**

</div>

---

## Architecture

Hexagonal Architecture (Ports & Adapters) with strict DDD.

```
infrastructure  →  application  →  domain
```

The domain knows nothing about Spring, databases, or HTTP.

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

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| No Hibernate/JPA | Native SQL via `JdbcClient` &mdash; full control, no magic |
| No Lombok | Explicit constructors, `public final` fields for value objects |
| Always Valid | Domain objects validate invariants in constructors |
| Composition Root | Use-cases wired via `@Configuration`, not `@Service` |
| One use-case = one class | Single responsibility, max ~15 lines of orchestration |
| Contract-first API | Controllers generated from `openapi/api.yaml`, not hand-written |

---

## Security

Dual authentication chain:

1. **API Key Filter** &mdash; `ApiKeyAuthFilter` extracts `X-API-Key` header, hashes with SHA-256, looks up active key in DB. Sets `ApiKeyAuthentication` (project-scoped, always READER). Short-circuits if found.

2. **JWT / OIDC** &mdash; falls back to OAuth2 Resource Server. Validates JWT, extracts `sub`, `email`, `name` claims. Auto-creates user on first login via `FindOrCreateUserUseCase`. First user matching `OIDC_ADMIN_EMAIL` is promoted to Platform Admin.

3. **Domain-level authorization** &mdash; use-cases call `callerAccess.resolve(projectId).ensure(Permission.WRITE_TOGGLES)`. Platform Admins bypass project role checks.

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

---

## Default Environments

The platform exposes a configurable list of default environment names (`DEV`, `TEST`, `PROD`, ...) that can be bootstrapped into a new project at creation time. The list lives in `application.yml` under `app.environments.defaults` (overridable via `APP_DEFAULT_ENVIRONMENTS`).

- **Single source of truth** &mdash; defaults live only in config, never in the database. Each project gets its own independent rows in the `environment` table.
- **Fail-fast validation** &mdash; `EnvironmentDefaultsValidator` validates each name on startup using the same `Environment.validateAndNormalize` rules. The application refuses to boot if any name violates `^[A-Z][A-Z0-9_]*$`, exceeds 50 characters, or duplicates another entry.
- **Field semantics** on `POST /projects`: omitting `environments` bootstraps **all** defaults; empty array opts out; non-empty subset bootstraps exactly those names.

---

## Development

```bash
# Start dependencies
docker compose up -d postgres keycloak

# Run from source
cd backend
mvn spring-boot:run
```

The backend starts on port **8080**. Liquibase runs migrations automatically.

API spec: [`src/main/resources/openapi/api.yaml`](src/main/resources/openapi/api.yaml)

Swagger UI: [localhost:8080/docs](http://localhost:8080/docs)

---

<p align="center"><a href="../README.md">&larr; Back to project</a></p>
