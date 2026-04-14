<div align="center">

# Homni Togli &mdash; Backend

REST API для Homni Togli.

**[English documentation](README.md)** &middot; **[README проекта](../README_RU.md)**

</div>

---

## Архитектура

Гексагональная архитектура (Ports & Adapters) со строгим DDD.

```
infrastructure  →  application  →  domain
```

Домен ничего не знает о Spring, базах данных или HTTP.

```
src/main/java/com/homni/togli/
├── domain/
│   ├── model/          Агрегаты, value objects, enum-ы
│   └── exception/      Доменные исключения (NotFound, AccessDenied, Conflict, Validation)
├── application/
│   ├── usecase/        Один класс на операцию (CreateToggle, ListToggles, ...)
│   └── port/out/       Интерфейсы репозиториев, CallerPort, CallerProjectAccessPort
└── infrastructure/
    ├── adapter/
    │   ├── inbound/rest/         Контроллеры + презентеры (domain → API)
    │   └── outbound/persistence/ JDBC-адаптеры (JdbcClient, нативный SQL)
    ├── security/                  Auth-фильтры, JWT-конвертер, OIDC авто-регистрация
    ├── exception/                 GlobalExceptionHandler
    └── config/                    CompositionRootConfig, SecurityConfig, CORS
```

### Архитектурные решения

| Решение | Обоснование |
|---------|-------------|
| Без Hibernate/JPA | Нативный SQL через `JdbcClient` &mdash; полный контроль, без магии |
| Без Lombok | Явные конструкторы, `public final` поля для value objects |
| Always Valid | Доменные объекты валидируют инварианты в конструкторах |
| Composition Root | Use-cases подключаются через `@Configuration`, а не `@Service` |
| Один use-case = один класс | Единственная ответственность, ~15 строк оркестрации |
| Contract-first API | Контроллеры генерируются из `openapi/api.yaml`, не пишутся вручную |

---

## Безопасность

Двойная цепочка аутентификации:

1. **API Key Filter** &mdash; `ApiKeyAuthFilter` извлекает заголовок `X-API-Key`, хеширует SHA-256, ищет активный ключ в БД. Устанавливает `ApiKeyAuthentication` (привязан к проекту, всегда READER). При совпадении остальные фильтры пропускаются.

2. **JWT / OIDC** &mdash; fallback на OAuth2 Resource Server. Валидирует JWT, извлекает claims `sub`, `email`, `name`. Автоматически создаёт пользователя при первом входе через `FindOrCreateUserUseCase`. Первый пользователь с `OIDC_ADMIN_EMAIL` повышается до Platform Admin.

3. **Авторизация на уровне домена** &mdash; use-cases вызывают `callerAccess.resolve(projectId).ensure(Permission.WRITE_TOGGLES)`. Platform Admin обходит проверки ролей проекта.

---

## Обработка ошибок

Доменные исключения маппятся на HTTP-коды через `GlobalExceptionHandler`:

| Исключение | HTTP | Код |
|------------|------|-----|
| `DomainNotFoundException` | 404 | `NOT_FOUND` |
| `DomainAccessDeniedException` | 403 | `FORBIDDEN` |
| `DomainConflictException` | 409 | `CONFLICT` |
| `DomainValidationException` | 422 | `VALIDATION_ERROR` |

Ошибки безопасности: `TOKEN_EXPIRED` (401), `UNAUTHORIZED` (401), `FORBIDDEN` (403).

---

## Дефолтные окружения

Платформа предоставляет настраиваемый список дефолтных имён окружений (`DEV`, `TEST`, `PROD`, ...), которые можно создать в новом проекте при его создании. Список лежит в `application.yml` под ключом `app.environments.defaults` (переопределяется через `APP_DEFAULT_ENVIRONMENTS`).

- **Единый источник истины** &mdash; дефолты живут только в конфиге, никогда в БД. Каждый проект получает свои независимые строки в таблице `environment`.
- **Fail-fast валидация** &mdash; `EnvironmentDefaultsValidator` валидирует каждое имя на старте теми же правилами `Environment.validateAndNormalize`. Приложение не поднимется, если хотя бы одно имя нарушает `^[A-Z][A-Z0-9_]*$`, длиннее 50 символов или встречается дважды.
- **Семантика поля** в `POST /projects`: отсутствие `environments` создаёт **все** дефолты; пустой массив — явный отказ; непустое подмножество — только перечисленные.

---

## База данных

7 таблиц, управляемых миграциями Liquibase:

```
project
├── feature_toggle ──* toggle_environment *── environment
├── project_membership *── app_user
└── api_key
```

| Таблица | Ключевые колонки | Примечания |
|---------|-----------------|------------|
| `project` | `id`, `slug` (unique), `name`, `archived` | Корневой агрегат |
| `app_user` | `id`, `oidc_subject` (unique), `email` (unique), `platform_role` | Создаётся автоматически при OIDC-логине |
| `project_membership` | `project_id`, `user_id`, `role` | Уникально по `(project, user)` |
| `environment` | `project_id`, `name` | Уникально по `(project, name)` |
| `feature_toggle` | `project_id`, `name` | Уникально по `(project, name)` |
| `toggle_environment` | `toggle_id`, `environment_id`, `enabled` | Композитный PK, состояние per-env |
| `api_key` | `project_id`, `token_hash` (unique), `active`, `expires_at` | SHA-256 хеш, filtered index по активным ключам |

Все ID — UUID. Временные метки — `TIMESTAMPTZ`. Каскадное удаление на `toggle_environment` (через toggle) и `project_membership` (через user).

---

## Разработка

```bash
# Запуск зависимостей
docker compose up -d postgres keycloak

# Запуск из исходников
cd backend
mvn spring-boot:run
```

Бэкенд запускается на порту **8080**. Liquibase автоматически выполняет миграции.

API-спецификация: [`src/main/resources/openapi/api.yaml`](src/main/resources/openapi/api.yaml)

Swagger UI: [localhost:8080/docs](http://localhost:8080/docs)

---

<p align="center"><a href="../README_RU.md">&larr; К README проекта</a></p>
