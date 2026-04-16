/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.internal;

import com.homni.togli.sdk.FeatureToggle;
import com.homni.togli.sdk.TogliClient;
import com.homni.togli.sdk.application.port.out.TogliApiPort;
import com.homni.togli.sdk.domain.exception.TogliException;
import com.homni.togli.sdk.domain.exception.TogliNotFoundException;
import com.homni.togli.sdk.domain.model.EnvironmentPage;
import com.homni.togli.sdk.domain.model.Pagination;
import com.homni.togli.sdk.domain.model.ProjectInfo;
import com.homni.togli.sdk.domain.model.Toggle;
import com.homni.togli.sdk.domain.model.TogglePage;
import com.homni.togli.sdk.domain.model.ToggleState;
import com.homni.togli.sdk.infrastructure.cache.ToggleCache;
import com.homni.togli.sdk.infrastructure.config.TogliConfiguration;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("DefaultTogliClient")
class DefaultTogliClientTest {

    private TogliClient client;

    @BeforeEach
    void setUp() {
        StubApi api = new StubApi();
        api.toggles.add(toggle("dark-mode", "DEV", true));
        api.toggles.add(toggle("checkout-v2", "DEV", false));

        TogliConfiguration config = new TogliConfiguration(
                "http://localhost", "key", "slug",
                Duration.ofMinutes(60), null, null,
                true, true, null, "DEV", null, "test-svc", null);

        InMemoryCache cache = new InMemoryCache();
        for (Toggle t : api.toggles) {
            cache.map.put(t.name, t);
        }

        ProjectInfo project = new ProjectInfo("proj-1", "SLUG", "Test",
                Optional.empty(), false, Instant.now(), Optional.empty());

        client = new DefaultTogliClient(api, cache, project, config);
    }

    @AfterEach
    void tearDown() {
        client.close();
    }

    @Nested
    @DisplayName("isEnabled")
    class IsEnabled {

        @Test
        @DisplayName("returns true for enabled toggle in default environment")
        void returnsTrueForEnabled() {
            assertThat(client.isEnabled("dark-mode")).isTrue();
        }

        @Test
        @DisplayName("returns false for disabled toggle")
        void returnsFalseForDisabled() {
            assertThat(client.isEnabled("checkout-v2")).isFalse();
        }

        @Test
        @DisplayName("returns false for unknown toggle")
        void returnsFalseForUnknown() {
            assertThat(client.isEnabled("nonexistent")).isFalse();
        }

        @Test
        @DisplayName("returns true with explicit environment")
        void returnsTrueWithExplicitEnv() {
            assertThat(client.isEnabled("dark-mode", "DEV")).isTrue();
        }
    }

    @Nested
    @DisplayName("toggle")
    class ToggleLookup {

        @Test
        @DisplayName("returns toggle by name")
        void returnsToggleByName() {
            Toggle found = client.toggle("dark-mode");

            assertThat(found.name).isEqualTo("dark-mode");
            assertThat(found.isEnabledIn("DEV")).isTrue();
        }

        @Test
        @DisplayName("throws TogliNotFoundException for unknown toggle")
        void throwsForUnknown() {
            assertThatThrownBy(() -> client.toggle("nonexistent"))
                    .isInstanceOf(TogliNotFoundException.class);
        }
    }

    @Nested
    @DisplayName("allToggles")
    class AllToggles {

        @Test
        @DisplayName("returns all cached toggles")
        void returnsAll() {
            List<Toggle> all = client.allToggles();

            assertThat(all).hasSize(2);
            assertThat(all).extracting(t -> t.name)
                    .containsExactlyInAnyOrder("dark-mode", "checkout-v2");
        }
    }

    @Nested
    @DisplayName("evaluate")
    class Evaluate {

        @Test
        @DisplayName("runs enabled Runnable when toggle is on")
        void runsEnabledRunnable() {
            AtomicReference<String> result = new AtomicReference<>();

            client.evaluate("dark-mode",
                    () -> result.set("enabled"), () -> result.set("disabled"));

            assertThat(result.get()).isEqualTo("enabled");
        }

        @Test
        @DisplayName("runs disabled Runnable when toggle is off")
        void runsDisabledRunnable() {
            AtomicReference<String> result = new AtomicReference<>();

            client.evaluate("checkout-v2",
                    () -> result.set("enabled"), () -> result.set("disabled"));

            assertThat(result.get()).isEqualTo("disabled");
        }

        @Test
        @DisplayName("returns enabled Supplier value when toggle is on")
        void returnsEnabledSupplier() {
            String result = client.evaluate("dark-mode",
                    (java.util.function.Supplier<String>) () -> "new",
                    (java.util.function.Supplier<String>) () -> "old");

            assertThat(result).isEqualTo("new");
        }

        @Test
        @DisplayName("returns disabled Supplier value when toggle is off")
        void returnsDisabledSupplier() {
            String result = client.evaluate("checkout-v2",
                    (java.util.function.Supplier<String>) () -> "new",
                    (java.util.function.Supplier<String>) () -> "old");

            assertThat(result).isEqualTo("old");
        }
    }

    @Nested
    @DisplayName("proxy")
    class ProxyTest {

        @Test
        @DisplayName("routes to enabled implementation when toggle is on")
        void routesToEnabled() {
            Greeter enabled = new Greeter() {
                @Override public String greet() { return "Hello!"; }
                @Override public String bye() { return "Goodbye!"; }
            };
            Greeter disabled = new Greeter() {
                @Override public String greet() { return "Hi."; }
                @Override public String bye() { return "Bye."; }
            };

            Greeter proxy = client.proxy(Greeter.class, enabled, disabled);

            assertThat(proxy.greet()).isEqualTo("Hello!");
        }

        @Test
        @DisplayName("routes to disabled implementation when toggle is off")
        void routesToDisabled() {
            Greeter enabled = new Greeter() {
                @Override public String greet() { return "Hello!"; }
                @Override public String bye() { return "Goodbye!"; }
            };
            Greeter disabled = new Greeter() {
                @Override public String greet() { return "Hi."; }
                @Override public String bye() { return "Bye."; }
            };

            Greeter proxy = client.proxy(Greeter.class, enabled, disabled);

            assertThat(proxy.bye()).isEqualTo("Bye.");
        }

        @Test
        @DisplayName("rejects non-interface type")
        void rejectsNonInterface() {
            assertThatThrownBy(() -> client.proxy(String.class, "a", "b"))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }

    @Nested
    @DisplayName("errorListener")
    class ErrorListenerTest {

        @Test
        @DisplayName("notifies error listener and returns false when API fails")
        void notifiesOnError() {
            AtomicReference<TogliException> captured = new AtomicReference<>();

            TogliConfiguration config = new TogliConfiguration(
                    "http://localhost", "key", "slug",
                    Duration.ofMinutes(60), null, null,
                    false, false, captured::set, "DEV", null, "test-svc", null);

            StubApi failingApi = new StubApi() {
                @Override
                public TogglePage fetchToggles(String projectId, int page, int size) {
                    throw new TogliNotFoundException("Toggle", "broken");
                }
            };

            ProjectInfo project = new ProjectInfo("proj-1", "SLUG", "Test",
                    Optional.empty(), false, Instant.now(), Optional.empty());

            try (TogliClient errorClient = new DefaultTogliClient(
                    failingApi, new InMemoryCache(), project, config)) {

                boolean result = errorClient.isEnabled("broken", "DEV");

                assertThat(result).isFalse();
                assertThat(captured.get()).isInstanceOf(TogliNotFoundException.class);
            }
        }
    }

    @Nested
    @DisplayName("projectInfo")
    class ProjectInfoAccess {

        @Test
        @DisplayName("returns resolved project info")
        void returnsProjectInfo() {
            assertThat(client.projectInfo().id).isEqualTo("proj-1");
        }
    }

    // ── test doubles ──────────────────────────────────────────

    interface Greeter {
        @FeatureToggle(name = "dark-mode")
        String greet();

        @FeatureToggle(name = "checkout-v2")
        String bye();
    }

    private static Toggle toggle(String name, String env, boolean enabled) {
        return new Toggle(UUID.randomUUID().toString(), "proj-1", name,
                Optional.empty(), List.of(new ToggleState(env, enabled)),
                Instant.now(), Optional.empty());
    }

    static class StubApi implements TogliApiPort {
        final List<Toggle> toggles = new ArrayList<>();

        @Override
        public ProjectInfo fetchProjectBySlug(String slug) {
            return new ProjectInfo("proj-1", slug, "Test",
                    Optional.empty(), false, Instant.now(), Optional.empty());
        }

        @Override
        public TogglePage fetchToggles(String projectId, int page, int size) {
            return new TogglePage(toggles, new Pagination(0, size, toggles.size(), 1));
        }

        @Override
        public Toggle fetchToggle(String projectId, String toggleId) {
            return toggles.stream().filter(t -> t.id.equals(toggleId)).findFirst().orElseThrow();
        }

        @Override
        public EnvironmentPage fetchEnvironments(String projectId, int page, int size) {
            return new EnvironmentPage(List.of(), new Pagination(0, size, 0, 0));
        }
    }

    /**
     * Simple in-memory cache that implements the public ToggleCache interface.
     */
    static class InMemoryCache implements ToggleCache {
        final Map<String, Toggle> map = new ConcurrentHashMap<>();

        @Override
        public Optional<Toggle> findByName(String name) {
            return Optional.ofNullable(map.get(name));
        }

        @Override
        public List<Toggle> all() {
            return List.copyOf(map.values());
        }

        @Override
        public void refresh(List<Toggle> toggles) {
            map.clear();
            for (Toggle t : toggles) {
                map.put(t.name, t);
            }
        }

        @Override
        public void start() {}

        @Override
        public void stop() {}
    }
}
