<div align="center">

# Homni Togli &mdash; Frontend

Admin dashboard for Homni Togli.

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

## Error Handling

Errors flow from HTTP response to UI through typed values &mdash; no exceptions cross layer boundaries.

```
HTTP status code
  → Repository._mapError() → Failure subclass
    → FutureEither<T> (Either<Failure, T>)
      → Cubit.fold() → emit(Error(failure))
        → BlocListener → Snackbar (warning / error)
        → BlocBuilder  → Error page with Retry
```

**Failure types** (sealed class):

| Failure | HTTP | UI |
|---------|------|----|
| `AuthFailure` | 401 | Token refresh / re-login |
| `ForbiddenFailure` | 403 | Full-screen "Access Denied" page |
| `NotFoundFailure` | 404 | Yellow warning snackbar |
| `ConflictFailure` | 409 | Yellow warning snackbar |
| `ValidationFailure` | 4xx | Red error snackbar |
| `ServerFailure` | 5xx | Red error snackbar |
| `NetworkFailure` | timeout / no connection | Red error snackbar |

Every repository method returns `FutureEither<T>` &mdash; no `try/catch` in cubits or UI.

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
