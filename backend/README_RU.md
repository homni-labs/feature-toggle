<div align="center">
<img src="assets/feature_toggle_logo_spring.jpeg" width="600" alt="Feature Toggle Logo">

# Homni Feature Toggle Backend

[![Build](https://github.com/homni-labs/feature-toggle/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/homni-labs/feature-toggle/actions/workflows/docker-publish.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

> REST API для Homni Feature Toggle &mdash; Spring Boot 3.4, гексагональная архитектура, PostgreSQL, OpenAPI 3.0, OIDC + API-ключи.

**[English documentation](README.md)** &middot; **[README проекта](../README_RU.md)**

</div>

---

## Архитектура

Гексагональная архитектура (Ports & Adapters) со строгим DDD.

```
domain/           Чистая Java: агрегаты, value objects, доменные исключения
application/      Use-cases (один класс = одна операция) + интерфейсы портов
infrastructure/   Spring, JDBC-адаптеры, REST-контроллеры, безопасность
```

**`infrastructure` &rarr; `application` &rarr; `domain`** &mdash; домен ничего не знает о Spring, базах данных или HTTP.

| Решение | Обоснование |
|---------|-------------|
| Без Hibernate/JPA | Нативный SQL через `JdbcClient` &mdash; полный контроль, без магии |
| Без Lombok | Явные конструкторы, `public final` поля для value objects |
| Always Valid | Доменные объекты валидируют инварианты в конструкторах |
| Composition Root | Use-cases подключаются через `@Configuration`, а не `@Service` |

---

## Структура проекта

```
src/main/java/com/homni/featuretoggle/
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

Все ответы об ошибках имеют единый формат:

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

## Безопасность

Двойная цепочка аутентификации:

1. **API Key Filter** &mdash; `ApiKeyAuthFilter` извлекает заголовок `X-API-Key`, хеширует SHA-256, ищет активный ключ в БД. Устанавливает `ApiKeyAuthentication` (привязан к проекту, всегда READER). При совпадении остальные фильтры пропускаются.

2. **JWT / OIDC** &mdash; fallback на OAuth2 Resource Server. Валидирует JWT, извлекает claims `sub`, `email`, `name`. Автоматически создаёт пользователя при первом входе через `FindOrCreateUserUseCase`. Первый пользователь с `OIDC_ADMIN_EMAIL` повышается до Platform Admin.

3. **Авторизация на уровне домена** &mdash; use-cases вызывают `callerAccess.resolve(projectId).ensure(Permission.WRITE_TOGGLES)`. Platform Admin обходит проверки ролей проекта.

---

## Стек технологий

| | Технология |
|-|-----------|
| Runtime | Java 21, Spring Boot 3.4 |
| База данных | PostgreSQL 17, Liquibase |
| Безопасность | Spring Security, OAuth2 Resource Server (JWT) |
| Auth-провайдер | Keycloak (или любой OIDC-провайдер) |
| API | OpenAPI 3.0, кодогенерация контроллеров |
| CI/CD | GitHub Actions &rarr; Docker Hub |

---

<p align="center">Сделано с заботой в <a href="https://github.com/homni-labs">Homni Labs</a></p>
