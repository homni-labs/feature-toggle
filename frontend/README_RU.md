<div align="center">

# Homni Feature Toggle &mdash; Frontend

Панель управления для Homni Feature Toggle.

**[English documentation](README.md)** &middot; **[README проекта](../README_RU.md)**

</div>

---

## Архитектура

Clean Architecture с модульной структурой по фичам. Каждый из 7 модулей полностью изолирован и содержит собственные слои: domain, application, infrastructure, presentation.

```
lib/
├── app/            Точка входа, DI, роутинг, тема
├── core/           Общие доменные примитивы и виджеты
└── features/
    └── <feature>/
        ├── domain/           Модели, value objects, порты репозиториев
        ├── application/      Use-cases, Cubit-ы, sealed-состояния
        ├── infrastructure/   DTO, маперы, HTTP-репозитории
        └── presentation/     Экраны, виджеты
```

**Правило зависимостей:**

```
presentation → application → domain ← infrastructure
```

Domain ни от чего не зависит. Infrastructure реализует порты домена. Presentation общается только с application.

### Архитектурные решения

| Решение | Обоснование |
|---------|-------------|
| **Clean Architecture** | Строгое разделение слоёв &mdash; фичи тестируются и заменяются независимо |
| **BLoC/Cubit** | Предсказуемый state management с sealed-классами &mdash; без булевых флагов, без неоднозначных состояний |
| **Either&lt;Failure, T&gt;** | Ошибки &mdash; значения, не исключения. Каждый сбой типизирован, ничего не теряется |
| **Value Objects** | `UserId`, `Email`, `ProjectRole` вместо строк &mdash; невалидное состояние невозможно |
| **Один use-case = один класс** | Единственная ответственность, инъекция через конструктор, ~15 строк |
| **UI не знает об инфраструктуре** | Presentation-слой не имеет ни одного импорта HTTP, JSON или хранилища |
| **Contract-first API** | Контроллеры генерируются из OpenAPI-спецификации, не пишутся вручную |

---

## Auth Flow

OIDC Authorization Code с PKCE (S256):

1. **Discovery** &mdash; загружает `.well-known/openid-configuration`, валидирует issuer
2. **PKCE** &mdash; генерирует 32-байтный случайный verifier, создаёт S256 challenge
3. **State & Nonce** &mdash; хранятся в `sessionStorage` для защиты от CSRF и replay-атак
4. **Обмен токенов** &mdash; authorization code + code verifier &rarr; access token + refresh token
5. **Refresh** &mdash; guard от конкурентных вызовов через общий `Future`
6. **Хранение** &mdash; browser `sessionStorage` (очищается при закрытии вкладки)

---

## Паттерн состояний

Sealed-состояния и `Either<Failure, T>` работают вместе:

1. **Use-case** возвращает `Either<Failure, T>` из репозитория
2. **Cubit** преобразует результат в sealed-состояние:
   - `Loading` &rarr; `Loaded(data)` при успехе
   - `Loading` &rarr; `Error(failure)` при ошибке
3. **UI** использует `BlocConsumer` &mdash; `listener` для побочных эффектов (snackbar, навигация), `builder` для рендеринга
4. **Exhaustive switch** &mdash; компилятор Dart отлавливает необработанные состояния

---

## Модули

| Модуль | Ответственность |
|--------|----------------|
| `auth` | OIDC/PKCE аутентификация, управление токенами |
| `projects` | CRUD проектов, поиск, архивация |
| `toggles` | CRUD тогглов, состояние per-environment |
| `environments` | Управление окружениями в проекте |
| `members` | Членство в проекте и назначение ролей |
| `api_keys` | Выпуск и отзыв API-ключей |
| `users` | Администрирование пользователей платформы |

---

## Разработка

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

Конфигурация загружается из `web/config.json` при старте &mdash; никаких `--dart-define` для локальной разработки не нужно.

---

<p align="center"><a href="../README_RU.md">&larr; К README проекта</a></p>
