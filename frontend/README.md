<div align="center">

# Homni Feature Toggle &mdash; Frontend

Admin dashboard for Homni Feature Toggle.

**[Russian documentation](README_RU.md)** &middot; **[Project README](../README.md)**

</div>

---

## Architecture

Clean Architecture with feature-based modularization. Each of the 7 feature modules is fully isolated with its own domain, application, infrastructure, and presentation layers.

```
lib/
├── app/            Entry point, DI, routing, theme
├── core/           Shared domain primitives and widgets
└── features/
    └── <feature>/
        ├── domain/           Models, value objects, repository ports
        ├── application/      Use-cases, Cubits, sealed states
        ├── infrastructure/   DTOs, mappers, HTTP repositories
        └── presentation/     Screens, widgets
```

**Dependency rule:**

```
presentation → application → domain ← infrastructure
```

Domain depends on nothing. Infrastructure implements domain ports. Presentation talks to application only.

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Clean Architecture** | Strict layer separation makes features testable and replaceable independently |
| **BLoC/Cubit** | Predictable state management with sealed classes &mdash; no boolean flags, no ambiguous states |
| **Either&lt;Failure, T&gt;** | Errors are values, not exceptions. Every failure is typed, nothing is silently swallowed |
| **Value Objects** | `UserId`, `Email`, `ProjectRole` instead of raw strings &mdash; invalid state is unrepresentable |
| **One use-case = one class** | Single-responsibility, constructor-injected, max ~15 lines |
| **No infrastructure in UI** | Presentation layer has zero knowledge of HTTP, JSON, or storage |
| **Contract-first API** | Controllers generated from OpenAPI spec, not hand-written |

---

## Auth Flow

OIDC Authorization Code with PKCE (S256):

1. **Discovery** &mdash; fetches `.well-known/openid-configuration`, validates issuer
2. **PKCE** &mdash; generates 32-byte random verifier, creates S256 challenge
3. **State & Nonce** &mdash; stored in `sessionStorage` for CSRF and replay protection
4. **Token Exchange** &mdash; authorization code + code verifier &rarr; access token + refresh token
5. **Refresh** &mdash; concurrent refresh guard deduplicates parallel calls via shared `Future`
6. **Storage** &mdash; browser `sessionStorage` (cleared on tab close, not persistent)

---

## State Pattern

Sealed states and `Either<Failure, T>` work together:

1. **Use-case** returns `Either<Failure, T>` from repository
2. **Cubit** folds the result into a sealed state:
   - `Loading` &rarr; `Loaded(data)` on success
   - `Loading` &rarr; `Error(failure)` on failure
3. **UI** uses `BlocConsumer` &mdash; `listener` for side effects (snackbar, navigation), `builder` for rendering
4. **Exhaustive switch** &mdash; Dart compiler catches any unhandled state

---

## Feature Modules

| Module | Responsibility |
|--------|---------------|
| `auth` | OIDC/PKCE authentication, token management |
| `projects` | Project CRUD, search, archive |
| `toggles` | Feature toggle CRUD, per-environment state |
| `environments` | Environment management per project |
| `members` | Project membership and role assignment |
| `api_keys` | API key issuance, revocation |
| `users` | Platform user administration |

---

## Development

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

Runtime config is loaded from `web/config.json` at startup &mdash; no `--dart-define` flags needed for local development.

---

<p align="center"><a href="../README.md">&larr; Back to project</a></p>
