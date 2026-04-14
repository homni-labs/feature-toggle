<div align="center">

# Togli Java SDK

Zero-dependency Java client for [Togli](../../README.md). No magic, no frameworks — just works.

**[Russian documentation](README_RU.md)** &middot; **[Project README](../../README.md)**

</div>

---

## ✨ Features

- **Zero dependencies** &mdash; only `java.*` imports, Java 17+
- **Thread-safe** with background polling cache
- **Simple API** &mdash; `client.isEnabled("toggle", "PROD")`, `evaluate()`, `proxy()`
- **API Key authentication** &mdash; read-only, project-scoped
- **Auto-refresh** &mdash; picks up toggle changes automatically
- **Error listener** &mdash; `onError` callback without crashing

---

## 🚀 Quick Start

### Maven

```xml
<dependency>
    <groupId>com.homni</groupId>
    <artifactId>togli-java-sdk</artifactId>
    <version>0.1.0-SNAPSHOT</version>
</dependency>
```

### Usage

```java
// Create once at application startup
TogliClient client = TogliClients.builder()
    .baseUrl("http://localhost:8080")
    .apiKey("hft_your_api_key")
    .projectSlug("my-project")
    .defaultEnvironment("PROD")
    .onError(e -> logger.warn("Toggle error: {}", e.getMessage()))
    .onReady(c -> logger.info("Togli loaded {} toggles", c.allToggles().size()))
    .build();

// Simple check — uses the default environment
if (client.isEnabled("dark-mode")) {
    renderDarkMode();
}

// Explicit environment
if (client.isEnabled("beta-feature", "DEV")) { ... }

// Fallback — run different logic based on toggle state
client.evaluate("new-checkout",
    () -> processNewCheckout(),     // toggle ON
    () -> processLegacyCheckout()); // toggle OFF
```

### Interface Proxy

Route entire service implementations based on toggle state using `@FeatureToggle` on interface methods:

```java
// 1. Define interface with @FeatureToggle
public interface CheckoutService {

    @FeatureToggle(name = "new-checkout")
    PaymentResult checkout(Order order);
}

// 2. Two implementations
public class NewCheckout implements CheckoutService { ... }
public class LegacyCheckout implements CheckoutService { ... }

// 3. Create proxy — SDK routes calls based on toggle state
CheckoutService service = client.proxy(
    CheckoutService.class,
    new NewCheckout(),       // toggle ON  → here
    new LegacyCheckout());   // toggle OFF → here

// 4. Use as a normal service
service.checkout(order);  // SDK checks toggle, routes automatically
```

If `environment` is not specified in the annotation, the `defaultEnvironment` from the builder is used. You can also set it explicitly: `@FeatureToggle(name = "dark-mode", environment = "PROD")`.

> [!NOTE]
> The client is designed to live for the entire application lifecycle. Resources are released automatically via a JVM shutdown hook &mdash; no need to call `close()` manually.

---

## ⚙️ Configuration

```java
TogliClient client = TogliClients.builder()
    .baseUrl("http://localhost:8080")
    .apiKey("hft_your_api_key")
    .projectSlug("my-project")
    .defaultEnvironment("PROD")
    .pollingInterval(Duration.ofMinutes(30))
    .requestTimeout(Duration.ofSeconds(5))
    .connectTimeout(Duration.ofSeconds(3))
    .onError(e -> logger.warn(e.getMessage()))
    .onReady(c -> logger.info("Loaded"))
    .cacheDisabled()
    .build();
```

**Required** &mdash; `build()` will throw `IllegalStateException` if any of these is missing:

| Option | Description |
|--------|-------------|
| `baseUrl` | Togli backend URL (e.g. `http://localhost:8080`) |
| `apiKey` | API key with `hft_...` prefix. Validated on startup &mdash; invalid or revoked key fails immediately |
| `projectSlug` | Project slug. Resolved to project ID on startup |

**Optional** &mdash; sensible defaults, override when needed:

| Option | Default | What happens if set |
|--------|---------|---------------------|
| `defaultEnvironment` | &mdash; | Enables `isEnabled("toggle-name")` without specifying env every time. Without it, only `isEnabled("name", "ENV")` works |
| `pollingInterval` | 60 min | How often the SDK refreshes toggle states from the backend. Min 5s. Lower = faster updates, more requests |
| `requestTimeout` | 10s | Max time to wait for a backend response |
| `connectTimeout` | 5s | Max time to establish a TCP connection |
| `onError(Consumer)` | &mdash; | Called when `isEnabled()` catches an error. Use for logging or monitoring. Without it, errors are silently swallowed |
| `onReady(Consumer)` | &mdash; | Called once after successful initialization. Receives the client &mdash; useful for logging toggle count, project info, etc. |
| `cacheDisabled()` | &mdash; | Disables background polling. Every `isEnabled()` call hits the API directly. Use only for testing or very low traffic |

---

## ⚡ Startup Behavior

On `build()`, the SDK:

1. Validates the API key by calling the backend
2. Resolves the project slug to a project ID
3. Fetches all toggles (initial cache load)

If the API key is invalid or revoked &rarr; `TogliAuthenticationException` (fail fast).

---

## 🔄 Auto-Refresh

The SDK keeps your toggles fresh by polling the backend (default: every 60 minutes) and picks up all changes automatically:

- Toggle enabled / disabled
- New toggles created
- Toggles deleted
- Project archived (all toggles become disabled)

Call `client.refresh()` to force an immediate refresh.

---

## 📖 API Reference

| Method | Returns | Description |
|--------|---------|-------------|
| `isEnabled(name)` | `boolean` | Check toggle in default environment. Returns `false` on any error |
| `isEnabled(name, env)` | `boolean` | Check toggle in explicit environment. Returns `false` on any error |
| `toggle(name)` | `Toggle` | Get full toggle details. Throws `TogliNotFoundException` if not found |
| `allToggles()` | `List<Toggle>` | All toggles in the project |
| `allEnvironments()` | `List<EnvironmentInfo>` | All environments in the project |
| `projectInfo()` | `ProjectInfo` | Project metadata (id, name, slug, archived) |
| `evaluate(name, Runnable, Runnable)` | `void` | Run enabled/disabled action based on toggle state |
| `evaluate(name, Supplier, Supplier)` | `<T>` | Return enabled/disabled value based on toggle state |
| `proxy(Class, enabled, disabled)` | `<T>` | Create interface proxy with `@FeatureToggle` routing |
| `refresh()` | `void` | Force immediate cache refresh |

All `evaluate` and `proxy` methods also have overloads with explicit environment parameter.

---

## 🛡 Error Handling

`isEnabled()` **never throws** and **never crashes** your app. On any error (network failure, server 500, timeout) it silently returns `false`.

But errors don't disappear &mdash; the `onError` callback lets you observe them without affecting the return value:

```java
TogliClient client = TogliClients.builder()
    .baseUrl("http://localhost:8080")
    .apiKey("hft_your_api_key")
    .projectSlug("my-project")
    .onError(error -> {
        // Log it, send to Sentry, increment a metric — up to you
        logger.warn("Toggle evaluation failed: {} ({})",
            error.getMessage(), error.getClass().getSimpleName());
    })
    .build();

// This will ALWAYS return true or false, never throw
boolean enabled = client.isEnabled("dark-mode", "PROD");
```

**How it works:**

1. `isEnabled()` tries to evaluate the toggle from cache (or API if cache is disabled)
2. If an error occurs &rarr; the `onError` listener is called with the exception
3. `isEnabled()` returns `false`
4. Your application continues running normally

The listener itself is wrapped in a safety net &mdash; even if it throws, the SDK won't crash.

**Exception types** (all extend `TogliException`):

| Exception | Cause |
|-----------|-------|
| `TogliAuthenticationException` | Invalid or revoked API key (401) |
| `TogliAccessDeniedException` | Insufficient permissions (403) |
| `TogliNotFoundException` | Toggle or project not found (404) |
| `TogliServerException` | Server error (4xx / 5xx) |
| `TogliNetworkException` | Connection failure or timeout |

> [!NOTE]
> `onError` only applies to `isEnabled()`. Other methods like `toggle()` and `allToggles()` throw exceptions normally &mdash; they are not silent.

---

## 🏗 Architecture

```
com.homni.togli.sdk/
├── TogliClient                     Public interface (isEnabled, toggle, refresh, ...)
├── TogliClients                    Static factory → builder()
│
├── domain/
│   ├── model/
│   │   ├── Toggle                  Toggle with per-environment states
│   │   ├── ToggleState             Environment name + enabled flag
│   │   ├── ProjectInfo             Resolved project metadata
│   │   ├── EnvironmentInfo         Environment metadata
│   │   ├── Pagination              Page metadata
│   │   ├── TogglePage              Paginated toggle result
│   │   └── EnvironmentPage         Paginated environment result
│   └── exception/
│       ├── TogliException          Abstract base (RuntimeException)
│       ├── TogliAuthenticationException  401
│       ├── TogliAccessDeniedException    403
│       ├── TogliNotFoundException        404
│       ├── TogliServerException          4xx / 5xx
│       ├── TogliNetworkException         Connection / timeout
│       └── TogliParsingException         Malformed JSON
│
├── application/port/out/
│   └── TogliApiPort                Outbound interface (fetchToggles, fetchProject, ...)
│
├── infrastructure/
│   ├── http/
│   │   ├── HttpTogliApiAdapter     java.net.http.HttpClient, implements TogliApiPort
│   │   ├── JsonParser              Hand-rolled recursive descent parser
│   │   ├── JsonObject              Parsed JSON object wrapper
│   │   ├── JsonArray               Parsed JSON array wrapper
│   │   └── ApiUrls                 URL path builder
│   ├── cache/
│   │   ├── ToggleCache             Cache interface
│   │   ├── PollingToggleCache      ScheduledExecutorService + volatile Map
│   │   ├── NoOpToggleCache         Pass-through (no caching)
│   │   └── CacheFactory            Creates cache based on config
│   └── config/
│       └── TogliConfiguration      Immutable config value object
│
└── internal/
    ├── DefaultTogliClient          TogliClient implementation
    └── TogliClientBuilder          Fluent builder with validation
```

Hexagonal Architecture. Domain layer is pure Java with zero framework imports.

---

## 🔒 Thread Safety

`TogliClient` instances are fully thread-safe. Share one instance across all threads in your application. The polling cache uses a volatile reference swap &mdash; reads are lock-free.

---

## 📋 Examples

See [Spring Boot example](../examples/spring-boot/) &mdash; REST app demonstrating every SDK feature via HTTP endpoints.

---

<p align="center"><a href="../../README.md">&larr; Back to project</a></p>
