<div align="center">
<img src="assets/images/feature_toggle_flutter.jpeg" width="600" alt="Feature Toggle">

# Feature Toggle Frontend

Панель управления для [Homni Feature Toggle](https://github.com/homni-labs/feature-toggle) &mdash; Flutter Web, Clean Architecture, BLoC/Cubit, OIDC/PKCE.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![BLoC](https://img.shields.io/badge/State-BLoC-blueviolet)](https://bloclibrary.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-teal)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

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

### Архитектурные решения

| Решение | Обоснование |
|---------|-------------|
| **Clean Architecture** | Строгое разделение слоёв &mdash; фичи тестируются и заменяются независимо |
| **BLoC/Cubit** | Предсказуемый state management с sealed-классами &mdash; без булевых флагов, без неоднозначных состояний |
| **Either&lt;Failure, T&gt;** | Ошибки &mdash; значения, не исключения. Каждый сбой типизирован, ничего не теряется |
| **Value Objects** | `UserId`, `Email`, `ProjectRole` вместо строк &mdash; невалидное состояние невозможно |
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
| Ошибки | fpdart | `Either<Failure, T>` &mdash; функциональная обработка без исключений |
| DI | get_it | Легковесный, без кодогенерации, lazy singletons |
| Авторизация | OIDC/PKCE | Стандартный протокол, работает с Keycloak или любым провайдером |
| HTTP | package:http | Минимальная зависимость, достаточная для REST |

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

<p align="center">Сделано с заботой в <a href="https://github.com/homni-labs">Homni Labs</a></p>
