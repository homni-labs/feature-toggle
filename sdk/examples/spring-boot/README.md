# Togli SDK Example — Spring Boot

E-commerce store that uses feature toggles to control UI theme, checkout flow, shipping, and promotions.

## Prerequisites

1. Togli backend running (`docker compose up -d` from project root)
2. A project with an API key (create via dashboard at [localhost:3000](http://localhost:3000), or via [Swagger UI](http://localhost:8080/docs), or directly in the database)
3. Create these toggles in your project and enable/disable them in the `DEV` environment:
   - `dark-mode` — UI theme toggle
   - `new-checkout` — checkout flow switch
   - `free-shipping` — shipping cost toggle
   - `promo-banner` — promotional banner

   The example uses `DEV` as the default environment (configured in `application.yml`). Make sure your project has a `DEV` environment and the toggles are assigned to it. If you use a different environment, update `togli.default-environment` in `application.yml` accordingly.

## Run

```bash
# Build SDK and add to local Maven repository (~/.m2)
cd sdk/java && mvn install -q && cd ../..

# Start the example (port 8090)
cd sdk/examples/spring-boot
mvn spring-boot:run
```

Edit `src/main/resources/application.yml` to set your API key and project slug.

## Endpoints

| URL | Feature | SDK Method |
|-----|---------|------------|
| `GET /store/theme` | Dark/light theme | `isEnabled("dark-mode")` |
| `GET /store/checkout` | New vs legacy checkout | `proxy()` + `@FeatureToggle` |
| `GET /store/shipping` | Free vs paid shipping | `evaluate()` with `Supplier` |
| `GET /store/banner` | Promo banner text | `evaluate()` with `Runnable` |
| `GET /store/debug` | All toggles + project info | `allToggles()` + `projectInfo()` |

## Try It

```bash
# Which theme is active?
curl http://localhost:8090/store/theme

# New or legacy checkout?
curl http://localhost:8090/store/checkout

# Free shipping enabled?
curl http://localhost:8090/store/shipping

# What does the banner say?
curl http://localhost:8090/store/banner

# See all toggles
curl http://localhost:8090/store/debug
```

Now go to the Togli dashboard and flip a toggle. To see the change immediately, force a cache refresh:

```bash
curl http://localhost:8090/store/refresh
```

Then call any endpoint again — the behavior changes.
