<div align="center">

# Togli Java SDK

Zero-dependency Java-клиент для платформы [Togli](../../README_RU.md).

**[English documentation](README.md)** &middot; **[README проекта](../../README_RU.md)**

</div>

---

## Возможности

- **Zero dependencies** &mdash; только `java.*` импорты, Java 17+
- **Потокобезопасный** с фоновым кэшем и polling
- **Простой API** &mdash; `client.isEnabled("toggle", "PROD")`
- **API Key аутентификация** &mdash; read-only, привязан к проекту
- **Auto-refresh** &mdash; подхватывает изменения тогглов автоматически
- **Error listener** &mdash; `onError` callback без падения приложения

---

## Быстрый старт

### Maven

```xml
<dependency>
    <groupId>com.homni</groupId>
    <artifactId>togli-java-sdk</artifactId>
    <version>0.1.0-SNAPSHOT</version>
</dependency>
```

### Использование

```java
// Создаём один раз при старте приложения
TogliClient client = TogliClients.builder()
    .baseUrl("http://localhost:8080")
    .apiKey("hft_your_api_key")
    .projectSlug("my-project")
    .defaultEnvironment("PROD")
    .onError(e -> logger.warn("Toggle error: {}", e.getMessage()))
    .onReady(c -> logger.info("Togli loaded {} toggles", c.allToggles().size()))
    .build();

// Просто — используется default environment из builder
if (client.isEnabled("dark-mode")) {
    renderDarkMode();
}

// Явное указание окружения — работает всегда, даже без defaultEnvironment
if (client.isEnabled("beta-feature", "DEV")) { ... }
```

> [!NOTE]
> Клиент рассчитан на весь жизненный цикл приложения. Ресурсы освобождаются автоматически через JVM shutdown hook &mdash; вызывать `close()` вручную не нужно.

---

## Конфигурация

```java
TogliClient client = TogliClients.builder()
    .baseUrl("http://localhost:8080")         // обязательно
    .apiKey("hft_your_api_key")               // обязательно
    .projectSlug("my-project")                // обязательно
    .defaultEnvironment("PROD")              // для isEnabled(name) без env
    .pollingInterval(Duration.ofMinutes(30))  // по умолчанию: 60 мин
    .requestTimeout(Duration.ofSeconds(5))    // по умолчанию: 10с
    .connectTimeout(Duration.ofSeconds(3))    // по умолчанию: 5с
    .onError(e -> logger.warn(e.getMessage()))// callback при ошибке
    .onReady(c -> logger.info("Loaded"))      // callback при инициализации
    .cacheDisabled()                          // fetch на каждый вызов (без polling)
    .build();
```

**Обязательные** &mdash; `build()` бросит `IllegalStateException` если что-то не указано:

| Опция | Описание |
|-------|----------|
| `baseUrl` | URL бэкенда Togli (напр. `http://localhost:8080`) |
| `apiKey` | API-ключ с префиксом `hft_...`. Валидируется при старте &mdash; невалидный или отозванный ключ сразу падает |
| `projectSlug` | Slug проекта. Резолвится в project ID при старте |

**Необязательные** &mdash; разумные дефолты, переопределяйте по необходимости:

| Опция | По умолчанию | Что происходит если указать |
|-------|-------------|----------------------------|
| `defaultEnvironment` | &mdash; | Включает `isEnabled("toggle-name")` без указания env каждый раз. Без него работает только `isEnabled("name", "ENV")` |
| `pollingInterval` | 60 мин | Как часто SDK обновляет состояние тогглов с бэкенда. Мин 5с. Ниже = быстрее обновления, больше запросов |
| `requestTimeout` | 10с | Макс время ожидания ответа от бэкенда |
| `connectTimeout` | 5с | Макс время установки TCP-соединения |
| `onError(Consumer)` | &mdash; | Вызывается когда `isEnabled()` ловит ошибку. Используйте для логирования или мониторинга. Без него ошибки тихо проглатываются |
| `onReady(Consumer)` | &mdash; | Вызывается один раз после успешной инициализации. Получает клиент &mdash; удобно для логирования количества тогглов, инфы о проекте и т.д. |
| `cacheDisabled()` | &mdash; | Отключает фоновый polling. Каждый `isEnabled()` идёт напрямую в API. Используйте только для тестирования или очень низкого трафика |

---

## Поведение при старте

При вызове `build()` SDK:

1. Валидирует API-ключ, обращаясь к бэкенду
2. Резолвит slug проекта в project ID
3. Загружает все тогглы (первоначальное наполнение кэша)

Если API-ключ невалиден или отозван &rarr; `TogliAuthenticationException` (fail fast).

---

## Auto-Refresh

SDK периодически опрашивает бэкенд (по умолчанию: каждые 60 минут) и автоматически подхватывает все изменения:

- Тогл включён / выключен
- Создан новый тогл
- Тогл удалён
- Проект архивирован (все тогглы становятся disabled)

Вызовите `client.refresh()` для принудительного обновления.

---

## Обработка ошибок

`isEnabled()` **никогда не бросает исключений** и **никогда не роняет** приложение. При любой ошибке (сбой сети, сервер 500, таймаут) тихо возвращает `false`.

Но ошибки не исчезают &mdash; callback `onError` позволяет их отслеживать, не влияя на возвращаемое значение:

```java
TogliClient client = TogliClients.builder()
    .baseUrl("http://localhost:8080")
    .apiKey("hft_your_api_key")
    .projectSlug("my-project")
    .onError(error -> {
        // Залогировать, отправить в Sentry, увеличить метрику — на ваш выбор
        logger.warn("Toggle evaluation failed: {} ({})",
            error.getMessage(), error.getClass().getSimpleName());
    })
    .build();

// Это ВСЕГДА вернёт true или false, никогда не бросит исключение
boolean enabled = client.isEnabled("dark-mode", "PROD");
```

**Как это работает:**

1. `isEnabled()` пытается проверить тогл из кэша (или API если кэш выключен)
2. Если произошла ошибка &rarr; вызывается `onError` listener с исключением
3. `isEnabled()` возвращает `false`
4. Приложение продолжает работать нормально

Сам listener обёрнут в защитную обёртку &mdash; даже если он бросит исключение, SDK не упадёт.

**Типы исключений** (все наследуют `TogliException`):

| Исключение | Причина |
|-----------|---------|
| `TogliAuthenticationException` | Невалидный или отозванный API-ключ (401) |
| `TogliAccessDeniedException` | Недостаточно прав (403) |
| `TogliNotFoundException` | Тогл или проект не найден (404) |
| `TogliServerException` | Ошибка сервера (4xx / 5xx) |
| `TogliNetworkException` | Ошибка соединения или таймаут |

> [!NOTE]
> `onError` действует только на `isEnabled()`. Остальные методы (`toggle()`, `allToggles()`) бросают исключения как обычно &mdash; они не молчат.

---

## Архитектура

```
com.homni.togli.sdk/
├── TogliClient                     Публичный интерфейс (isEnabled, toggle, refresh, ...)
├── TogliClients                    Статическая фабрика → builder()
│
├── domain/
│   ├── model/
│   │   ├── Toggle                  Тогл с per-environment состояниями
│   │   ├── ToggleState             Имя окружения + enabled флаг
│   │   ├── ProjectInfo             Метаданные проекта
│   │   ├── EnvironmentInfo         Метаданные окружения
│   │   ├── Pagination              Метаданные страницы
│   │   ├── TogglePage              Пагинированный результат тогглов
│   │   └── EnvironmentPage         Пагинированный результат окружений
│   └── exception/
│       ├── TogliException          Абстрактный базовый (RuntimeException)
│       ├── TogliAuthenticationException  401
│       ├── TogliAccessDeniedException    403
│       ├── TogliNotFoundException        404
│       ├── TogliServerException          4xx / 5xx
│       ├── TogliNetworkException         Соединение / таймаут
│       └── TogliParsingException         Некорректный JSON
│
├── application/port/out/
│   └── TogliApiPort                Выходной интерфейс (fetchToggles, fetchProject, ...)
│
├── infrastructure/
│   ├── http/
│   │   ├── HttpTogliApiAdapter     java.net.http.HttpClient, реализует TogliApiPort
│   │   ├── JsonParser              Ручной recursive descent парсер
│   │   ├── JsonObject              Обёртка над распарсенным JSON-объектом
│   │   ├── JsonArray               Обёртка над распарсенным JSON-массивом
│   │   └── ApiUrls                 Построитель URL-путей
│   ├── cache/
│   │   ├── ToggleCache             Интерфейс кэша
│   │   ├── PollingToggleCache      ScheduledExecutorService + volatile Map
│   │   ├── NoOpToggleCache         Pass-through (без кэширования)
│   │   └── CacheFactory            Создаёт кэш на основе конфига
│   └── config/
│       └── TogliConfiguration      Иммутабельный конфиг (value object)
│
└── internal/
    ├── DefaultTogliClient          Реализация TogliClient
    └── TogliClientBuilder          Fluent builder с валидацией
```

Гексагональная архитектура. Доменный слой — чистая Java без импортов фреймворков.

---

## Потокобезопасность

Экземпляры `TogliClient` полностью потокобезопасны. Используйте один экземпляр на всё приложение. Polling кэш использует volatile reference swap &mdash; чтение без блокировок.

---

<p align="center"><a href="../../README_RU.md">&larr; К README проекта</a></p>
