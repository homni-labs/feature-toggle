<div align="center">
<img src="assets/images/feature_toggle_flutter.jpeg" width="600" alt="Feature Toggle">

# Feature Toggle Frontend

Панель управления для платформы [Homni Feature Toggle](https://github.com/homni-labs/feature-toggle-backend-spring) — self-hosted платформа фича-флагов с RBAC по проектам, мульти-окружениями и API-ключами.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![BLoC](https://img.shields.io/badge/State-BLoC-blueviolet)](https://bloclibrary.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-teal)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**[English documentation](README.md)**

</div>

---

<!-- TODO: заменить на реальные скриншоты -->
<p align="center">
  <img src="docs/screenshots/dashboard.png" width="80%" alt="Dashboard">
</p>

<p align="center">
  <img src="docs/screenshots/toggles.png" width="49%" alt="Toggles">&nbsp;
  <img src="docs/screenshots/members.png" width="49%" alt="Members">
</p>

---

## Начало работы

### Предусловия

- Flutter SDK >= 3.2 ([установка](https://docs.flutter.dev/get-started/install))
- Запущенный бэкенд с Keycloak ([инструкция](https://github.com/homni-labs/feature-toggle-backend-spring#quick-start))

### Запуск

```bash
flutter pub get
flutter run -d chrome --web-port 3000
```

Откройте [localhost:3000](http://localhost:3000). Учётные данные по умолчанию: `admin` / `admin`.

---

## Возможности

| | |
|-|-|
| **Изоляция проектов** | У каждого проекта свои тогглы, окружения, участники и API-ключи |
| **Управление тогглами** | Создание, включение/выключение, фильтрация по статусу и окружению, пагинация |
| **Контроль окружений** | Произвольные окружения деплоя — не ограничены DEV/STAGING/PROD |
| **Командный доступ** | Приглашение участников с ролями Admin, Editor, Reader на уровне проекта |
| **API-ключи** | Выпуск токенов со сроком действия для SDK и CI/CD |
| **Администрирование** | Управление пользователями и ролями на уровне платформы |
| **OIDC-авторизация** | OAuth 2.1 с PKCE, автоматическое обновление токенов, управление сессией |

---

## Архитектура

Фронтенд построен на **Clean Architecture** с модульной структурой по фичам. Каждый из 7 модулей полностью изолирован и содержит собственные слои: domain, application, infrastructure, presentation.

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

### Архитектурные решения

| Решение | Обоснование |
|---------|-------------|
| **Clean Architecture** | Строгое разделение слоёв — фичи тестируются и заменяются независимо |
| **BLoC/Cubit** | Предсказуемый state management с sealed-классами — без булевых флагов, без неоднозначных состояний |
| **Either&lt;Failure, T&gt;** | Ошибки — значения, не исключения. Каждый сбой типизирован, ничего не теряется |
| **Value Objects** | `UserId`, `Email`, `ProjectRole` вместо строк — невалидное состояние невозможно |
| **Один use-case = один класс** | Единственная ответственность, инъекция через конструктор, максимум 15 строк |
| **UI не знает об инфраструктуре** | Presentation-слой не имеет ни одного импорта HTTP, JSON или хранилища |

### Правило зависимостей

```
presentation → application → domain ← infrastructure
```

Domain ни от чего не зависит. Infrastructure реализует порты домена. Presentation общается только с application.

---

## Стек технологий

| Слой | Технология | Почему |
|------|-----------|--------|
| Фреймворк | Flutter 3.x (Web) | Единая кодовая база, быстрая итерация, web-first |
| State | flutter_bloc | Cubit + Dart 3 sealed states, предсказуемые rebuild-ы |
| Ошибки | fpdart | `Either<Failure, T>` — функциональная обработка без исключений |
| DI | get_it | Легковесный, без кодогенерации, lazy singletons |
| Авторизация | OIDC/PKCE | Стандартный протокол, работает с Keycloak или любым провайдером |
| HTTP | package:http | Минимальная зависимость, достаточная для REST |

---

## Структура проекта

```
features/
├── auth/            OIDC-авторизация, жизненный цикл токенов, сессия
├── projects/        CRUD проектов, настройки, архивация
├── toggles/         CRUD фича-флагов, фильтрация, пагинация
├── environments/    Управление окружениями деплоя
├── members/         RBAC на уровне проекта (Admin/Editor/Reader)
├── api_keys/        Выпуск и отзыв токенов
└── users/           Администрирование пользователей платформы
```

Каждая фича содержит 19 use-cases, 8 cubit-ов, 7 доменных моделей с value objects, 6 портов репозиториев с инфраструктурными реализациями.

---

## Дорожная карта

- [ ] Мобильная поддержка (Android, iOS)
- [ ] Десктоп поддержка (macOS, Windows, Linux)
- [ ] Локализация (i18n)
- [ ] Типобезопасная навигация (go_router)
- [ ] Просмотр журнала аудита
- [ ] Поиск и массовые операции над тогглами

---

## Участие в разработке

1. Форкните репозиторий
2. Создайте feature-ветку
3. Зафиксируйте изменения
4. Откройте Pull Request

Для крупных изменений сначала [создайте issue](https://github.com/homni-labs/feature-toggle-app/issues).

**Безопасность** — уязвимости сообщайте напрямую через [Telegram](https://t.me/zaytsev_dv) или zaytsev.dmitry9228@gmail.com. Не используйте публичные issues.

---

## Лицензия

[MIT](LICENSE)

<p align="center"><a href="https://github.com/homni-labs">Homni Labs</a></p>
