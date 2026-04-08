<div align="center">
<img src="assets/images/feature_toggle_flutter.jpeg" width="600" alt="Feature Toggle">

# Feature Toggle Frontend

Admin dashboard for [Homni Feature Toggle](https://github.com/homni-labs/feature-toggle) &mdash; Flutter Web, Clean Architecture, BLoC/Cubit, OIDC/PKCE.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![BLoC](https://img.shields.io/badge/State-BLoC-blueviolet)](https://bloclibrary.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-teal)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**[Документация на русском](README_RU.md)** &middot; **[Project README](../README.md)**

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

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Clean Architecture** | Strict layer separation makes features testable and replaceable independently |
| **BLoC/Cubit** | Predictable state management with sealed classes &mdash; no boolean flags, no ambiguous states |
| **Either&lt;Failure, T&gt;** | Errors are values, not exceptions. Every failure is typed, nothing is silently swallowed |
| **Value Objects** | `UserId`, `Email`, `ProjectRole` instead of raw strings &mdash; invalid state is unrepresentable |
| **One use-case = one class** | Single-responsibility, constructor-injected, max 15 lines |
| **No infrastructure in UI** | Presentation layer has zero knowledge of HTTP, JSON, or storage |

### Dependency Rule

```
presentation → application → domain ← infrastructure
```

Domain depends on nothing. Infrastructure implements domain ports. Presentation talks to application only.

---

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Flutter 3.x (Web) | Single codebase, fast iteration, web-first |
| State | flutter_bloc | Cubit + Dart 3 sealed states, predictable rebuilds |
| Errors | fpdart | `Either<Failure, T>` &mdash; functional error handling without exceptions |
| DI | get_it | Lightweight, no code generation, lazy singletons |
| Auth | OIDC/PKCE | Standard protocol, works with Keycloak or any provider |
| HTTP | package:http | Minimal dependency, sufficient for REST |

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

<p align="center">Made with care by <a href="https://github.com/homni-labs">Homni Labs</a></p>
