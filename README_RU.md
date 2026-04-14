<div align="center">

<table><tr>
<td><img src="assets/feature_toggle_logo.jpeg" width="250" alt="Homni Togli"></td>
<td>
<h1>Homni Togli</h1>
<p>Open-source платформа для управления фича-флагами с RBAC на уровне проектов, мультисредовым контролем и встроенным мониторингом.</p>
</td>
</tr></table>

<p>
  <a href="#быстрый-старт">Быстрый старт</a> &middot;
  <a href="#дорожная-карта">Roadmap</a>
</p>

**[English documentation](README.md)**

[![Build](https://github.com/homni-labs/feature-toggle/actions/workflows/ci.yml/badge.svg)](https://github.com/homni-labs/feature-toggle/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/homni-labs/feature-toggle)](https://github.com/homni-labs/feature-toggle/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/zaytsevdv/homni-togli)](https://hub.docker.com/r/zaytsevdv/homni-togli)
[![GitHub Stars](https://img.shields.io/github/stars/homni-labs/feature-toggle?style=social)](https://github.com/homni-labs/feature-toggle)

</div>

---

## Содержание

- [Почему Togli?](#почему-togli)
- [Возможности](#возможности)
- [Быстрый старт](#быстрый-старт)
- [Архитектура](#архитектура)
- [Технологический стек](#технологический-стек)
- [Мониторинг](#мониторинг)
- [API](#api)
- [Конфигурация](#конфигурация)
- [Разрешения](#разрешения)
- [Локальная разработка](#локальная-разработка)
- [Участие в разработке](#участие-в-разработке)
- [Дорожная карта](#дорожная-карта)
- [Сообщество и поддержка](#сообщество-и-поддержка)
- [Лицензия](#лицензия)

---

## Почему Togli?

Большинство решений для фича-флагов либо доступны только как SaaS, берут плату за каждого пользователя, либо не имеют нормального контроля доступа. Togli — другой:

- **Полный контроль** &mdash; разворачивайте на своей инфраструктуре, без привязки к вендору, без лимитов, данные не покидают вашу сеть
- **Изоляция проектов** &mdash; у каждого проекта свои тогглы, окружения, участники и API-ключи
- **Гранулярный RBAC** &mdash; Администратор платформы, Администратор проекта, Редактор, Читатель &mdash; чёткие границы прав на каждом уровне
- **Управление окружениями** &mdash; создавайте кастомные окружения для каждого проекта, не ограничиваясь DEV / STAGING / PROD
- **API по контракту** &mdash; спецификация OpenAPI 3.0 с кодогенерацией контроллеров, Swagger UI и скоупированными API-ключами
- **Встроенный мониторинг** &mdash; Prometheus, Grafana и Loki настроены из коробки с тремя готовыми дашбордами

---

## Возможности

- &#x1F512; **[OIDC-аутентификация](#конфигурация)** &mdash; Keycloak с кастомной брендированной SSO-страницей входа из коробки. Совместимость с любым OpenID Connect провайдером (Authentik, Auth0, Okta и др.). OAuth 2.1 + PKCE
- &#x1F4C1; **[Изоляция проектов](#архитектура)** &mdash; каждый проект — самодостаточное рабочее пространство со своими тогглами, окружениями, участниками и API-ключами
- &#x1F6E1; **[Гранулярный RBAC](#разрешения)** &mdash; Администратор платформы, Администратор проекта, Редактор, Читатель с детальной матрицей разрешений
- &#x1F30D; **[Мультисредовой контроль](#конфигурация)** &mdash; список дефолтных окружений задаётся через конфиг при старте; выбирайте, какие из них создать в новом проекте, а кастомные добавляйте отдельно
- &#x1F511; **[Аутентификация по API-ключам](#api)** &mdash; скоупированные read-only токены с опциональным сроком действия для CI/CD пайплайнов и внешних сервисов
- &#x1F4D6; **[OpenAPI 3.0](#api)** &mdash; полный контракт API с интерактивным Swagger UI по адресу `/docs`
- &#x1F5A5; **[Панель управления](#архитектура)** &mdash; полнофункциональный Flutter Web UI для управления проектами, тогглами, окружениями, участниками и API-ключами
- &#x1F4CA; **[Встроенный мониторинг](#мониторинг)** &mdash; метрики Prometheus, дашборды Grafana, агрегация логов Loki и Promtail &mdash; всё настроено и готово к использованию

---

## Быстрый старт

**1. Клонируйте репозиторий**

```bash
git clone https://github.com/homni-labs/feature-toggle.git
cd feature-toggle
```

**2. Запустите инфраструктуру** (PostgreSQL + Keycloak + Backend + Мониторинг)

```bash
docker compose up -d
```

**3. Запустите фронтенд**

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

| Сервис | URL | Учётные данные |
|--------|-----|----------------|
| Фронтенд | [localhost:3000](http://localhost:3000) | `admin` / `admin` |
| Backend API | [localhost:8080](http://localhost:8080) | Bearer JWT |
| Swagger UI | [localhost:8080/docs](http://localhost:8080/docs) | &mdash; |
| Keycloak Admin | [localhost:8180](http://localhost:8180) | `admin` / `admin` |
| Grafana | [localhost:3001](http://localhost:3001) | `admin` / `admin` |
| Prometheus | [localhost:9090](http://localhost:9090) | &mdash; |

> **Тестовые пользователи (Keycloak):** `admin` / `admin` (Администратор платформы), `editor` / `editor`, `reader` / `reader`.

```bash
# Проверка работоспособности бэкенда
curl http://localhost:8080/actuator/health
# {"status":"UP"}
```

> [!TIP]
> Все значения по умолчанию настроены для локальной разработки &mdash; работает из коробки без `.env` файла. Для кастомизации скопируйте `.env.example` в `.env` и отредактируйте.

---

## Архитектура

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
  │  Dashboards  ──► 3 pre-built dashboards             │
  │                                                     │
  └─────────────────────────────────────────────────────┘
```

**Backend** &mdash; Гексагональная архитектура (Ports & Adapters) со строгим Domain-Driven Design. Доменный слой не имеет зависимостей от фреймворка; use-case'ы — чистые оркестраторы; репозитории реализуют выходные порты через JDBC. Подробнее в [backend/README_RU.md](backend/README_RU.md).

**Frontend** &mdash; Чистая архитектура с модульной структурой по фичам (auth, projects, toggles, environments, members, API keys, users). BLoC/Cubit для управления состоянием с sealed-состояниями и функциональной обработкой ошибок. OIDC/PKCE аутентификация с редиректом на SSO-страницу. Подробнее в [frontend/README_RU.md](frontend/README_RU.md).

---

## Технологический стек

| Слой | Технологии |
|------|-----------|
| Backend | Java, Spring Boot, Spring Security, OAuth2, Liquibase, OpenAPI Generator |
| База данных | PostgreSQL |
| Аутентификация | Keycloak (пример из коробки, работает с любым OIDC-провайдером) |
| Frontend | Flutter Web, flutter_bloc (Cubit), fpdart, go_router |
| Мониторинг | Prometheus, Grafana, Loki, Promtail |
| Инфраструктура | Docker, Docker Compose, Nginx |

---

## Мониторинг

Togli поставляется с production-grade стеком мониторинга. Всё настроено из коробки &mdash; просто `docker compose up` и откройте Grafana.

**Готовые дашборды Grafana** (в `observability/grafana/dashboards/`):

| Дашборд | Метрики |
|---------|---------|
| Spring Boot | HTTP-запросы (RPS), латентность (p50 / p95 / p99), JVM-память, GC-паузы |
| Keycloak | События аутентификации, активные сессии, операции с токенами |
| PostgreSQL | Активные соединения, производительность запросов, размер БД |

**Пайплайн метрик:** Backend &rarr; `/actuator/prometheus` (Micrometer) &rarr; Prometheus (скрейпинг каждые 10 сек) &rarr; Grafana.

**Пайплайн логов:** Docker-контейнеры &rarr; Promtail &rarr; Loki &rarr; Grafana Explore.

| Компонент | URL | Назначение |
|-----------|-----|------------|
| Grafana | [localhost:3001](http://localhost:3001) | Дашборды и просмотр логов |
| Prometheus | [localhost:9090](http://localhost:9090) | Метрики и PromQL-запросы |

> [!NOTE]
> Дашборды в `observability/` — готовые примеры. Модифицируйте их или добавляйте свои через провижининг Grafana.

---

## API

Аутентификация: **Bearer JWT** (OIDC) или заголовок **`X-API-Key`**.

Полная спецификация OpenAPI 3.0: [`backend/src/main/resources/openapi/api.yaml`](backend/src/main/resources/openapi/api.yaml)

Интерактивный Swagger UI: [`/docs`](http://localhost:8080/docs) (при запущенном бэкенде)

**Формат ошибок** (единый конверт):

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

## Конфигурация

### Backend

Все переменные имеют разумные значения по умолчанию для локальной разработки.

| Переменная | По умолчанию | Описание |
|------------|-------------|----------|
| `DB_HOST` | `localhost` | Хост PostgreSQL |
| `DB_PORT` | `5432` | Порт PostgreSQL |
| `DB_NAME` | `homni_togli` | Имя базы данных |
| `DB_USER` | `homni` | Пользователь БД |
| `DB_PASSWORD` | `homni` | Пароль БД |
| `OIDC_ISSUER_URI` | `http://localhost:8180/realms/togli` | URI OIDC-издателя |
| `OIDC_ADMIN_EMAIL` | `admin@homni.local` | Email первого администратора (назначается при первом входе) |
| `APP_DEFAULT_ENVIRONMENTS` | `DEV,TEST,PROD` | Список дефолтных имён окружений через запятую. Каждое должно соответствовать `^[A-Z][A-Z0-9_]*$` (макс 50 символов). Валидируется при старте. |
| `CORS_ORIGINS` | `*` | Разрешённые CORS-источники |
| `LOG_LEVEL` | `DEBUG` | Уровень логирования |
| `OBSERVABILITY_ENABLED` | `true` | Включить эндпоинт метрик Prometheus |
| `PROMETHEUS_URL` | `http://localhost:9090` | URL сервера Prometheus |

> **Дефолтные окружения:** при создании проекта UI показывает чекбоксы для каждого имени из `APP_DEFAULT_ENVIRONMENTS`. Выбранные создаются как независимые строки внутри проекта &mdash; удаление `DEV` в одном проекте не затрагивает другие. Дефолты хранятся только в конфиге (единственный источник истины).

### Frontend

Конфигурация загружается из `/config.json` при старте приложения. Значения по умолчанию работают из коробки для локальной разработки.

| Переменная | По умолчанию | Описание |
|------------|-------------|----------|
| `apiBaseUrl` | `http://localhost:8081` | URL Backend API |
| `oidcIssuer` | `http://localhost:8180/realms/togli` | OIDC-издатель |
| `oidcClientId` | `togli-frontend` | OIDC Client ID |
| `oidcRedirectUri` | `http://localhost:3000/callback` | URI редиректа OIDC |
| `oidcPostLogoutRedirectUri` | `http://localhost:3000/` | URI редиректа после выхода |

### Свой SSO-провайдер

Keycloak в `sso/` — это пример настройки с преднастроенными тестовыми пользователями и кастомной темой страницы входа. **Togli работает с любым OIDC/OAuth провайдером** &mdash; Authentik, Auth0, Okta, Google Workspace или любым другим провайдером, поддерживающим OpenID Connect.

Для подключения своего провайдера:

```yaml
# docker-compose.yml
backend:
  environment:
    OIDC_ISSUER_URI: https://sso.example.com/realms/your-realm
    OIDC_ADMIN_EMAIL: your-admin@example.com
```

При первом входе с этим email пользователь автоматически получает роль **Администратор платформы**.

> [!NOTE]
> Пользователи управляются в SSO-провайдере (Keycloak или вашем собственном). При первом входе в Togli аккаунт пользователя создаётся в системе автоматически. Ручная регистрация пользователей не требуется.

---

## Разрешения

| Действие | Админ платформы | Админ проекта | Редактор | Читатель | API-ключ |
|----------|:-:|:-:|:-:|:-:|:-:|
| Создание / архивация проектов | + | | | | |
| Управление пользователями платформы | + | | | | |
| Управление участниками | + | + | | | |
| Управление API-ключами | + | + | | | |
| Управление окружениями | + | + | | | |
| Создание / обновление / удаление тогглов | + | + | + | | |
| Включение / выключение тогглов | + | + | + | | |
| Чтение тогглов | + | + | + | + | + |

> **Администратор платформы** имеет неограниченный доступ ко всем проектам. Остальные роли действуют в рамках проекта. **API-ключ** предоставляет read-only доступ для машинной интеграции.

---

## Локальная разработка

### Предварительные требования

| Инструмент | Версия |
|------------|--------|
| Java | 21+ |
| Maven | 3.9+ |
| Flutter | 3.2+ |
| Docker & Compose | Последняя |

### Backend

Запустите только инфраструктурные сервисы:

```bash
docker compose up -d postgres keycloak
```

Запустите бэкенд из исходников (дефолтные значения совпадают с Compose-конфигурацией):

```bash
cd backend
mvn spring-boot:run
```

Бэкенд запускается на порту **8080**. Liquibase автоматически выполняет миграции при старте.

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

Фронтенд запускается на порту **3000**. Конфигурация по умолчанию указывает на `localhost:8081` (API) и `localhost:8180` (Keycloak).

### Проверка

```bash
curl http://localhost:8080/actuator/health
# {"status":"UP"}
```

- Swagger UI: [localhost:8080/docs](http://localhost:8080/docs)
- Фронтенд: [localhost:3000](http://localhost:3000), войдите под `admin` / `admin`

### С мониторингом

Для запуска полного стека мониторинга при локальной разработке:

```bash
docker compose up -d postgres keycloak prometheus grafana loki promtail postgres-exporter
```

Grafana будет доступна по адресу [localhost:3001](http://localhost:3001) со всеми тремя дашбордами.

---

## Участие в разработке

1. Сделайте форк репозитория
2. Создайте ветку (`git checkout -b feature/amazing-feature`)
3. Закоммитьте изменения
4. Откройте Pull Request

Для крупных изменений сначала [создайте issue](https://github.com/homni-labs/feature-toggle/issues), чтобы обсудить предлагаемые улучшения.

Если у вас есть вопросы, идеи или предложения по проекту &mdash; пишите в [Telegram](https://t.me/zaytsev_dv) или на почту zaytsev.dmitry9228@gmail.com.

**Безопасность** &mdash; если вы обнаружили уязвимость, **не** создавайте публичный issue. Используйте те же контакты выше.

---

## Дорожная карта

- [ ] Java SDK &mdash; нативная клиентская библиотека
- [ ] Аудит-лог &mdash; отслеживание всех действий пользователей
- [ ] Вебхуки &mdash; оповещение внешних систем при изменении состояния тогглов
- [ ] Тогглы по расписанию &mdash; автоматическое включение / выключение в заданное время
- [ ] Обнаружение устаревших тогглов &mdash; поиск тогглов, не менявшихся N дней
- [ ] Поддержка Authentik &mdash; готовая интеграция как альтернативный OIDC-провайдер
- [ ] Бэкенд на Quarkus &mdash; альтернативный легковесный runtime
- [ ] Кастомизация дизайна &mdash; настройка цветов, логотипа и брендинга через конфигурацию

---

## Сообщество и поддержка

- [GitHub Issues](https://github.com/homni-labs/feature-toggle/issues) &mdash; баг-репорты и запросы на фичи
- [Telegram](https://t.me/zaytsev_dv) &mdash; вопросы и обратная связь
- Email: zaytsev.dmitry9228@gmail.com

---

## Лицензия

Проект лицензирован под [MIT License](LICENSE).

<p align="center">Сделано с заботой в <a href="https://github.com/homni-labs">Homni Labs</a></p>
