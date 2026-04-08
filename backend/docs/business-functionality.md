# Homni Feature Toggle — Бизнес-функционал

## Обзор

Платформа управления feature toggles с per-project разделением, RBAC и API-ключами для SDK-интеграции.

---

## 1. Ролевая модель

### Платформенные роли

| Роль | Описание |
|------|----------|
| **PLATFORM_ADMIN** | Полный контроль над платформой: все проекты, все пользователи. Обходит все проектные проверки доступа |
| **USER** | Обычный пользователь. Доступ к проектам через membership |

### Проектные роли

| Роль | Permissions | Что может |
|------|-----------|-----------|
| **ADMIN** | READ_TOGGLES, WRITE_TOGGLES, MANAGE_MEMBERS | Всё внутри проекта: CRUD тогглов, окружений, участников, API-ключей |
| **EDITOR** | READ_TOGGLES, WRITE_TOGGLES | CRUD тогглов и окружений. Не может управлять участниками и ключами |
| **READER** | READ_TOGGLES | Только чтение тогглов, окружений, списка участников |

### Матрица доступа

| Операция | READER | EDITOR | ADMIN | PLATFORM_ADMIN |
|----------|--------|--------|-------|----------------|
| Просмотр тогглов | + | + | + | + |
| Создание/изменение/удаление тогглов | - | + | + | + |
| Включение/отключение тогглов | - | + | + | + |
| Просмотр окружений | + | + | + | + |
| Создание/удаление окружений | - | + | + | + |
| Просмотр участников проекта | + | + | + | + |
| Управление участниками | - | - | + | + |
| Управление API-ключами | - | - | + | + |
| Создание проектов | - | - | - | + |
| Управление пользователями | - | - | - | + |

---

## 2. Проекты

### Создание проекта
- Только PLATFORM_ADMIN
- Обязательные поля: `key` (уникальный slug, 2-50 символов, uppercase), `name` (1-255 символов)
- Опциональное: `description`
- Участники добавляются отдельно после создания

### Список проектов
- PLATFORM_ADMIN видит все проекты
- USER видит только проекты, где он member
- В ответе: роль текущего пользователя в каждом проекте (`myRole`)

### Обновление проекта
- Требует MANAGE_MEMBERS (project ADMIN)
- Можно менять: `name`, `description`, `archived`

### Архивирование (readonly-режим)
- `PATCH /projects/{id}` с `{archived: true}` — заморозка проекта
- Архивированный проект:
  - Тогглы **продолжают работать** — SDK получает данные
  - API-ключи **валидны для чтения**
  - **Заблокировано**: любые создания, изменения, удалени��
- Разархивирование: `{archived: false}`

---

## 3. Feature Toggles

### Создание
- Требует WRITE_TOGGLES (EDITOR+)
- Обязательные: `name`, `environments` (минимум 1)
- Опциональное: `description`
- Environments должны существовать в проекте (валидация в use-case)
- Создаётся в состоянии **disabled**
- Имя уникально в рамках проекта

### Включение/отключение
- Через PATCH: `{enabled: true}` или `{enabled: false}`
- Идемпотентно — повторное включение уже включённого не вызывает ошибку
- Требует WRITE_TOGGLES

### Обновление
- Partial update: можно менять любую комбинацию `name`, `description`, `environments`, `enabled`
- Environments валидируются (должны существовать в проекте)
- Проект не должен быть архивирован

### Фильтрация и пагинация
- `GET /projects/{id}/toggles?enabled=true&environment=PROD&page=0&size=20`
- Фильтры опциональны, комбинируются через AND

### Удаление
- Каскадно удаляет связи toggle_environment
- Проект не должен быть архивирован

---

## 4. Окружения (Environments)

### Создание
- Требует WRITE_TOGGLES (EDITOR+)
- Имя нормализуется в uppercase
- Формат: начинается с буквы, только буквы, циф��ы, `_` (1-50 символов)
- Уникальность в рамках проекта

### Список
- Требует READ_TOGGLES (READER+)
- Без пагинации (обычно 3-10 окружений)

### Удаление
- Требует WRITE_TOGGLES (EDITOR+)
- **Нельзя удалить** если окружение используется хотя бы одним тогглом
- Проект не должен быть архивирован

---

## 5. API-ключи

### Назначение
- Для machine-to-machine доступа (SDK, CI/CD, автоматизация)
- **Всегда read-only** (роль READER) — нельзя создать ключ с EDITOR/ADMIN

### Выпуск
- Требует MANAGE_MEMBERS (project ADMIN)
- Параметры: `name`, опционально `expiresAt`
- Генерируется криптографически безопасный токен (32 байта, base64, префикс `hft_`)
- Raw-токен возвращается **один раз** при создании — потом только маскированная версия

### Безопасность
- Токен хешируется SHA-256 перед сохранением в БД
- При отображении маскируется: `hft_****abcd` (последние 4 символа)
- Привязан к конкретному проекту — нельзя использовать для другого проекта (403)

### Валидность
- Активен + не истёк по `expiresAt`
- Отозванный ключ не может быть восстановлен

### В ответе
- Имя проекта (`projectName`) для контекста

---

## 6. Участники проекта (Members)

### Добавление/изменение роли (upsert)
- `PUT /projects/{id}/members/{userId}` с `{role: "EDITOR"}`
- Если пользователь не member — добавляет с указанной ролью
- Если уже member — обновляет роль
- Требует MANAGE_MEMBERS (project ADMIN)
- Пользователь должен существовать на платформе

### Список участников
- Требует READ_TOGGLES (любой участник видит команду)
- Пагинация

### Удаление
- Требует MANAGE_MEMBERS (project ADMIN)
- Удаление membership не удаляет пользователя с платформы

### Один пользователь — много проектов
- Пользователь может быть ADMIN в проекте A и READER в проекте B
- Роли полностью независимы между проектами

---

## 7. Пользователи платформы (Users)

### Текущий по��ьзователь
- `GET /users/me` — любой аутентифицированный (JWT)
- Возвращает профиль: id, email, name, platformRole, active

### Поиск пользователей
- `GET /users/search?q=ivan` — любой аутентифицированный
- Ищет по email и name (case-insensitive, подстрока)
- До 20 результатов
- Используется для добавления участников в проект

### Список пользователей
- `GET /users` — только PLATFORM_ADMIN
- Пагинаци��

### Управление пользова��елями
- `PATCH /users/{userId}` — только PLATFORM_ADMIN
- Можно: повысить до PLATFORM_ADMIN, понизить до USER, заблокировать (disable), разблокировать (activate)
- **Нельзя изменять самого себя** (защита от случайного self-demote/disable)

---

## 8. Аутентификация

### OIDC (JWT)
- Основной способ для пользователей
- При первом логине: автоматическое создание пользователя (USER)
- JWT должен содержать claims: `sub`, `email`, `name` (или `preferred_username`)
- На каждый запрос: JWT → загрузка/создание AppUser → AppUserAuthentication

### API Key
- Для SDK и автоматизации
- Заголовок `X-API-Key`
- При запросе: хеширование токена → поиск в БД → проверка валидности → ApiKeyAuthentication
- Привязан к проекту — запрос к другому проекту → 403

### Bootstrap первого администратора
- Переменная `OIDC_ADMIN_EMAIL` (default: `admin@homni.local`)
- При первом логине пользователя с этим email → автоматическое повышение до PLATFORM_ADMIN
- Работает один раз (только если текущая роль USER)

---

## 9. API Endpoints (21 шт.)

### Проекты (3)
```
POST   /projects                                    Создать проект (PLATFORM_ADMIN)
GET    /projects                                    Список проектов (auth, с ролью)
PATCH  /projects/{projectId}                        Обновить/архивировать (MANAGE_MEMBERS)
```

### Тогглы (5)
```
GET    /projects/{projectId}/toggles                Список (READ_TOGGLES, фильтры+пагинация)
POST   /projects/{projectId}/toggles                Создать (WRITE_TOGGLES)
GET    /projects/{projectId}/toggles/{toggleId}     Получить (READ_TOGGLES)
PATCH  /projects/{projectId}/toggles/{toggleId}     Обновить/вкл/выкл (WRITE_TOGGLES)
DELETE /projects/{projectId}/toggles/{toggleId}     Удалить (WRITE_TOGGLES)
```

### Окружения (3)
```
GET    /projects/{projectId}/environments           Список (READ_TOGGLES)
POST   /projects/{projectId}/environments           Создать (WRITE_TOGGLES)
DELETE /projects/{projectId}/environments/{envId}    Удалить (WRITE_TOGGLES)
```

### API-ключи (3)
```
GET    /projects/{projectId}/api-keys               Список (MANAGE_MEMBERS)
POST   /projects/{projectId}/api-keys               Выпустить read-only (MANAGE_MEMBERS)
DELETE /projects/{projectId}/api-keys/{keyId}        Отозвать (MANAGE_MEMBERS)
```

### Участники (3)
```
GET    /projects/{projectId}/members                Список (READ_TOGGLES)
PUT    /projects/{projectId}/members/{userId}       Добавить/изменить роль (MANAGE_MEMBERS)
DELETE /projects/{projectId}/members/{userId}        Удалить (MANAGE_MEMBERS)
```

### Пользователи (4)
```
GET    /users/me                                    Текущий пользователь (auth)
GET    /users                                       Список (PLATFORM_ADMIN)
GET    /users/search?q=                             Поиск по email/name (auth)
PATCH  /users/{userId}                              Управление (PLATFORM_ADMIN, не self)
```

---

## 10. Бизнес-правила и инварианты

| Правило | Где проверяется |
|---------|----------------|
| Toggle не может существовать без environments | FeatureToggle конструктор |
| Environment name уникален в проекте | БД constraint + domain validation |
| Toggle name уникален в проекте | БД constraint |
| Project key уникален глобально | БД constraint |
| API-ключ всегда READER | IssuedApiKey (hardcoded) |
| Архивированный проект = readonly | ensureProjectNotArchived() в write use-cases |
| API-ключ не работает для чужого проекта | ApiKeyAuthentication.resolveAccess() |
| Админ не может менять себя | UpdateUserUseCase (self-check) |
| Нельзя удалить environment если он используется | DeleteEnvironmentUseCase |
| Email пользователя уникален | БД constraint + domain exception |
| OIDC subject привязывается один раз | AppUser.bindOidcSubject() guard |

---

## 11. Технический стек

| Компонент | Технология |
|-----------|-----------|
| Runtime | Java 21, Spring Boot 3.4 |
| БД | PostgreSQL 15+, TIMESTAMPTZ |
| Миграции | Liquibase |
| Безопасность | Spring Security, OAuth2 Resource Server (JWT) |
| Доступ к БД | JdbcClient (нативный SQL, без ORM) |
| API-документация | OpenAPI 3.0, Swagger UI (/docs) |
| Архитектура | Hexagonal (Ports & Adapters), DDD, чистый домен |
