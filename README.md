<div align="center">

<table><tr>
<td><img src="assets/feature_toggle_logo.jpeg" width="250" alt="Homni Togli"></td>
<td>
<h1>Homni Togli</h1>
<p>Open-source, self-hosted feature flag platform with per-project RBAC, multi-environment control, and built-in observability.</p>
</td>
</tr></table>

<p>
  <a href="#quick-start">Quick Start</a> &middot;
  <a href="#roadmap">Roadmap</a>
</p>

**[Документация на русском](README_RU.md)**

[![Build](https://github.com/homni-labs/feature-toggle/actions/workflows/ci.yml/badge.svg)](https://github.com/homni-labs/feature-toggle/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Backend](https://img.shields.io/docker/v/zaytsevdv/togli-backend?label=backend&sort=semver)](https://hub.docker.com/r/zaytsevdv/togli-backend)
[![Frontend](https://img.shields.io/docker/v/zaytsevdv/togli-frontend?label=frontend&sort=semver)](https://hub.docker.com/r/zaytsevdv/togli-frontend)


</div>

---

## Table of Contents

- [Why Togli?](#why-togli)
- [Features](#features)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [SDK](#sdk)
- [Tech Stack](#tech-stack)
- [Observability](#observability)
- [API](#api)
- [Configuration](#configuration)
- [Permissions](#permissions)
- [Local Development](#local-development)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [Community & Support](#community--support)
- [License](#license)

---

<a id="why-togli"></a>

## 💡 Why Togli?

Most feature flag tools are SaaS-only, charge per seat, or lock you out of granular access control. Togli takes a different path:

- **Full ownership** &mdash; deploy on your infrastructure, no vendor lock-in, no usage limits, no data leaving your network
- **Per-project isolation** &mdash; each project has its own toggles, environments, team members, and API keys
- **Granular RBAC** &mdash; Platform Admin, Project Admin, Editor, Reader &mdash; clear permission boundaries at every level
- **Environment-aware toggles** &mdash; create custom environments per project, not limited to DEV / STAGING / PROD
- **Contract-first API** &mdash; OpenAPI 3.0 spec with code-generated controllers, Swagger UI, and scoped API keys
- **Built-in observability** &mdash; Prometheus, Grafana, and Loki pre-configured out of the box with five ready-to-use dashboards

---

<a id="features"></a>

## ✨ Features

- &#x1F512; **[OIDC Authentication](#configuration)** &mdash; Keycloak with a custom branded SSO login page out of the box. Compatible with any OpenID Connect provider (Authentik, Auth0, Okta, etc.). OAuth 2.1 + PKCE
- &#x1F4C1; **[Project Isolation](#architecture)** &mdash; each project is a self-contained workspace with its own toggles, environments, members, and API keys
- &#x1F6E1; **[Granular RBAC](#permissions)** &mdash; Platform Admin, Project Admin, Editor, Reader with a fine-grained permissions matrix
- &#x1F30D; **[Multi-Environment Control](#configuration)** &mdash; platform-wide default environments configured at startup; pick which ones to bootstrap into each new project, and add custom ones per project later
- &#x1F511; **[API Key Authentication](#api)** &mdash; scoped read-only tokens with optional expiration for CI/CD pipelines and external services
- &#x1F4D6; **[OpenAPI 3.0](#api)** &mdash; full API contract with interactive Swagger UI at `/docs`
- &#x1F5A5; **[Admin Dashboard](#architecture)** &mdash; full-featured Flutter Web UI for managing projects, toggles, environments, members, and API keys
- &#x1F4CA; **[Built-in Observability](#observability)** &mdash; Prometheus metrics, Grafana dashboards, Loki log aggregation, and Promtail &mdash; all pre-configured and ready to use
- &#x2615; **[Java SDK](#sdk)** &mdash; zero-dependency client library with `isEnabled()`, `evaluate()`, interface proxy routing, background cache

---

<a id="quick-start"></a>

## 🚀 Quick Start

### Option A: Pull from Docker Hub (recommended)

Pre-built images are available on Docker Hub — no need to build anything locally:

```bash
docker pull zaytsevdv/togli-backend:latest
docker pull zaytsevdv/togli-frontend:latest
```

Then use them in your `docker-compose.yml`:

```yaml
backend:
  image: zaytsevdv/togli-backend:latest
frontend:
  image: zaytsevdv/togli-frontend:latest
```

### Option B: Build from source

**1. Clone the repository**

```bash
git clone https://github.com/homni-labs/feature-toggle.git
cd feature-toggle
```

**2. Start all services** (PostgreSQL + Keycloak + Backend + Frontend + Observability)

```bash
docker compose up -d --build
```

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | [localhost:3000](http://localhost:3000) | `admin` / `admin` |
| Backend API | [localhost:8080](http://localhost:8080) | Bearer JWT |
| Swagger UI | [localhost:8080/docs](http://localhost:8080/docs) | &mdash; |
| Keycloak Admin | [localhost:8180](http://localhost:8180) | `admin` / `admin` |
| Grafana | [localhost:3001](http://localhost:3001) | `admin` / `admin` |
| Prometheus | [localhost:9090](http://localhost:9090) | &mdash; |

> **Test users (Keycloak):** `admin` / `admin` (Platform Admin), `editor` / `editor`, `reader` / `reader`.

```bash
# Verify the backend is running
curl http://localhost:8080/actuator/health
# {"status":"UP"}
```

> [!TIP]
> All default values are pre-configured for local development &mdash; works out of the box without any `.env` file. To customize, copy `.env.example` to `.env` and edit as needed.

---

<a id="architecture"></a>

## 🏗 Architecture

```
                          ┌───────────┐
                          │  Browser  │
                          └─────┬─────┘
                                │
                   ┌────────────┼────────────┐
                   │            │             │
            ┌──────┴──────┐    │     ┌───────┴───────┐
            │  Frontend   │    │     │     SSO       │
            │  Dashboard  │◄───┘     │  OIDC Provider│
            └──────┬──────┘          └───────┬───────┘
                   │                         │
                   │    REST API + JWT        │
                   └────────────┬─────────────┘
                                │
                     ┌──────────┴──────────┐
                     │      Backend        │
                     └──────────┬──────────┘
                                │
                     ┌──────────┴──────────┐
                     │     Database        │
                     └─────────────────────┘

  ┌─ Observability ─────────────────────────────────────┐
  │                                                     │
  │  Metrics     ◄── Backend, SSO, Database             │
  │  Logs        ◄── All containers                     │
  │  Dashboards  ──► 5 pre-built dashboards             │
  │                                                     │
  └─────────────────────────────────────────────────────┘
```

**Backend** &mdash; Hexagonal Architecture (Ports & Adapters) with strict Domain-Driven Design. The domain layer has zero framework dependencies; use-cases are pure orchestrators; repositories implement outbound ports via JDBC. See [backend/README.md](backend/README.md) for details.

**Frontend** &mdash; Clean Architecture with feature-based modules (auth, projects, toggles, environments, members, API keys, users). BLoC/Cubit state management with sealed states and functional error handling. OIDC/PKCE authentication with redirect to the SSO login page. See [frontend/README.md](frontend/README.md) for details.

---

<a id="sdk"></a>

## 🔌 SDK

Official client libraries for integrating Togli into your applications.

| SDK | Language | Status |
|-----|----------|--------|
| [Java SDK](sdk/java/README.md) | Java 21+ | Available |

### Java SDK

Zero-dependency client library with background polling cache.

```java
TogliClient client = TogliClients.builder()
    .baseUrl("http://localhost:8080")
    .apiKey("hft_your_api_key")
    .projectSlug("my-project")
    .defaultEnvironment("PROD")
    .build();

if (client.isEnabled("dark-mode")) { ... }

// Fallback: toggle ON → new logic, toggle OFF → old logic
client.evaluate("new-checkout",
    () -> processNew(),
    () -> processLegacy());
```

See [sdk/java/README.md](sdk/java/README.md) for full documentation and [Spring Boot example](sdk/examples/spring-boot/) to try it live.

---

<a id="tech-stack"></a>

## 🛠 Tech Stack

| Layer | Technologies |
|-------|-------------|
| Backend | Java, Spring Boot, Spring Security, OAuth2, Liquibase, OpenAPI Generator |
| Database | PostgreSQL |
| Auth | Keycloak (bundled example, works with any OIDC provider) |
| Frontend | Flutter Web, flutter_bloc (Cubit), fpdart, go_router |
| SDK | Java (zero-dependency, java.net.http, Proxy API) |
| Observability | Prometheus, Grafana, Loki, Promtail |
| Infra | Docker, Docker Compose, Nginx |
| Docker Images | [togli-backend](https://hub.docker.com/r/zaytsevdv/togli-backend), [togli-frontend](https://hub.docker.com/r/zaytsevdv/togli-frontend) |

---

<a id="observability"></a>

## 📊 Observability

Togli comes with a full observability stack out of the box. Everything just works &mdash; just `docker compose up` and open Grafana.

**Pre-built Grafana dashboards** (in `observability/grafana/dashboards/`):

| Dashboard | Metrics |
|-----------|---------|
| Spring Boot | HTTP request rates, latencies (p50 / p95 / p99), JVM memory, GC pauses |
| Keycloak | Authentication events, active sessions, token operations |
| PostgreSQL | Active connections, query performance, database size |
| Node Exporter | CPU, memory, disk, network of the host machine |
| cAdvisor | Per-container CPU, memory, network usage |

**Metrics pipeline:** Backend exposes `/actuator/prometheus` (Micrometer) &rarr; Prometheus scrapes every 10s &rarr; Grafana visualizes.

**Log pipeline:** All Docker containers &rarr; Promtail &rarr; Loki &rarr; Grafana Explore view.

| Component | URL | Purpose |
|-----------|-----|---------|
| Grafana | [localhost:3001](http://localhost:3001) | Dashboards & log exploration |
| Prometheus | [localhost:9090](http://localhost:9090) | Raw metrics & PromQL queries |

> [!NOTE]
> The dashboards in `observability/` are ready-to-use examples. Customize them or add your own via Grafana provisioning.

---

<a id="api"></a>

## 📡 API

Authentication: **Bearer JWT** (OIDC) or **`X-API-Key`** header.

Full OpenAPI 3.0 spec: [`backend/src/main/resources/openapi/api.yaml`](backend/src/main/resources/openapi/api.yaml)

Interactive Swagger UI: [`/docs`](http://localhost:8080/docs) (when backend is running)

**Error response format** (consistent envelope):

```json
{
  "payload": {
    "code": "NOT_FOUND",
    "message": "Toggle not found"
  },
  "meta": {
    "timestamp": "2026-04-14T12:00:00Z"
  }
}
```

---

<a id="configuration"></a>

## ⚙️ Configuration

### Backend

Everything works out of the box — no config needed for local dev.

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `homni_togli` | Database name |
| `DB_USER` | `homni` | Database user |
| `DB_PASSWORD` | `homni` | Database password |
| `OIDC_ISSUER_URI` | `http://localhost:8180/realms/togli` | OIDC issuer URI |
| `OIDC_ADMIN_EMAIL` | `admin@homni.local` | First admin email (bootstrapped on first login) |
| `APP_DEFAULT_ENVIRONMENTS` | `DEV,TEST,PROD` | Comma-separated default environment names. Each must match `^[A-Z][A-Z0-9_]*$` (max 50 chars). Validated on startup. |
| `CORS_ORIGINS` | `*` | Allowed CORS origins |
| `LOG_LEVEL` | `DEBUG` | Application log level |
| `OBSERVABILITY_ENABLED` | `true` | Enable Prometheus metrics endpoint |
| `PROMETHEUS_URL` | `http://localhost:9090` | Prometheus server URL |

> **Default environments:** when creating a project, the UI shows checkboxes for each name from `APP_DEFAULT_ENVIRONMENTS`. Selected ones are materialized as independent rows inside the new project &mdash; deleting `DEV` from one project does not affect any other. Defaults live only in config (the single source of truth).

### Frontend

Frontend config is loaded from `/config.json` at startup. Works out of the box — no manual setup needed.

| Variable | Default | Description |
|----------|---------|-------------|
| `apiBaseUrl` | `http://localhost:8081` | Backend API URL |
| `oidcIssuer` | `http://localhost:8180/realms/togli` | OIDC issuer |
| `oidcClientId` | `togli-frontend` | OIDC client ID |
| `oidcRedirectUri` | `http://localhost:3000/callback` | OIDC redirect URI |
| `oidcPostLogoutRedirectUri` | `http://localhost:3000/` | Post-logout redirect URI |

### Bring Your Own SSO

The bundled Keycloak in `sso/` is an example setup with pre-configured test users and a custom login theme. **Togli works with any OIDC/OAuth provider** &mdash; Authentik, Auth0, Okta, Google Workspace, or any other provider that supports OpenID Connect.

To use your own provider:

```yaml
# docker-compose.yml
backend:
  environment:
    OIDC_ISSUER_URI: https://sso.example.com/realms/your-realm
    OIDC_ADMIN_EMAIL: your-admin@example.com
```

On first login with that email, the user is automatically promoted to **Platform Admin**.

> [!NOTE]
> Users are managed in your SSO provider (Keycloak or your own). When a user logs in to Togli for the first time, their account is automatically created in the system. No manual user registration is required.

---

<a id="permissions"></a>

## 🔐 Permissions

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

<a id="local-development"></a>

## 💻 Local Development

### Prerequisites

| Tool | Version |
|------|---------|
| Java | 21+ |
| Maven | 3.9+ |
| Flutter | 3.2+ |
| Docker & Compose | Latest |

### Backend

Start only the infrastructure services:

```bash
docker compose up -d postgres keycloak
```

Run the backend from source (defaults match the Compose setup):

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

The frontend starts on port **3000**. Default config points to `localhost:8081` (API) and `localhost:8180` (Keycloak).

### Verify

```bash
curl http://localhost:8080/actuator/health
# {"status":"UP"}
```

- Swagger UI: [localhost:8080/docs](http://localhost:8080/docs)
- Frontend: [localhost:3000](http://localhost:3000), log in with `admin` / `admin`

### With Observability

To run the full observability stack during local development:

```bash
docker compose up -d postgres keycloak prometheus grafana loki promtail postgres-exporter
```

Grafana will be available at [localhost:3001](http://localhost:3001) with all three dashboards pre-configured.

---

<a id="contributing"></a>

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes
4. Open a Pull Request

Please [open an issue](https://github.com/homni-labs/feature-toggle/issues) first for major changes to discuss what you'd like to improve.

If you have questions, ideas, or suggestions about the project &mdash; feel free to reach out via [Telegram](https://t.me/zaytsev_dv) or email at zaytsev.dmitry9228@gmail.com.

**Security** &mdash; if you discover a vulnerability, please **do not** open a public issue. Use the same contacts above.

---

<a id="roadmap"></a>

## 🗺 Roadmap

- [ ] Percentage rollout &mdash; enable a toggle for N% of requests with consistent hashing
- [ ] Snapshot & restore &mdash; save toggle states as a snapshot, one-click rollback if something breaks
- [ ] Audit log &mdash; track all user actions with timeline view per toggle
- [ ] Webhooks &mdash; notify external systems on toggle state changes
- [ ] Scheduled toggles &mdash; auto-enable / disable at a specific time
- [ ] Stale toggle detection &mdash; find toggles that haven't changed in N days
- [ ] Toggle promotion pipeline &mdash; promote toggle state through environments (DEV &rarr; TEST &rarr; PROD)
- [ ] Publish Java SDK to Maven Central
- [ ] Authentik support &mdash; out-of-the-box integration as an alternative OIDC provider
- [ ] Frontend theming &mdash; customizable colors, logo, and branding via configuration

---

<a id="community--support"></a>

## 💬 Community & Support

- [GitHub Issues](https://github.com/homni-labs/feature-toggle/issues) &mdash; bug reports and feature requests
- [Telegram](https://t.me/zaytsev_dv) &mdash; direct questions and feedback
- Email: zaytsev.dmitry9228@gmail.com

---

## License

This project is licensed under the [MIT License](LICENSE).

<p align="center">Made with care by <a href="https://github.com/homni-labs">Homni Labs</a></p>
