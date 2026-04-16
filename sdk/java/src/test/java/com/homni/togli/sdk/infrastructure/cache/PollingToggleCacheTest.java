/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.cache;

import com.homni.togli.sdk.application.port.out.TogliApiPort;
import com.homni.togli.sdk.domain.model.EnvironmentInfo;
import com.homni.togli.sdk.domain.model.EnvironmentPage;
import com.homni.togli.sdk.domain.model.Pagination;
import com.homni.togli.sdk.domain.model.ProjectInfo;
import com.homni.togli.sdk.domain.model.Toggle;
import com.homni.togli.sdk.domain.model.TogglePage;
import com.homni.togli.sdk.domain.model.ToggleState;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("PollingToggleCache")
class PollingToggleCacheTest {

    private PollingToggleCache cache;

    @AfterEach
    void tearDown() {
        if (cache != null) {
            cache.stop();
        }
    }

    @Test
    @DisplayName("findByName returns toggle after start")
    void findByNameAfterStart() {
        Toggle toggle = toggle("dark-mode", true);
        cache = createCache(List.of(toggle));
        cache.start();

        Optional<Toggle> found = cache.findByName("dark-mode");

        assertThat(found).isPresent();
        assertThat(found.get().isEnabledIn("DEV")).isTrue();
    }

    @Test
    @DisplayName("all returns all cached toggles")
    void allReturnsCachedToggles() {
        cache = createCache(List.of(toggle("a", true), toggle("b", false)));
        cache.start();

        List<Toggle> all = cache.all();

        assertThat(all).hasSize(2);
    }

    @Test
    @DisplayName("findByName returns empty for unknown toggle")
    void findByNameReturnsEmptyForUnknown() {
        cache = createCache(List.of(toggle("exists", true)));
        cache.start();

        assertThat(cache.findByName("nonexistent")).isEmpty();
    }

    @Test
    @DisplayName("refresh replaces cache content atomically")
    void refreshReplacesContent() {
        cache = createCache(List.of(toggle("old", true)));
        cache.start();
        assertThat(cache.findByName("old")).isPresent();

        cache.refresh(List.of(toggle("new", false)));

        assertThat(cache.findByName("old")).isEmpty();
        assertThat(cache.findByName("new")).isPresent();
    }

    @Test
    @DisplayName("start and stop lifecycle completes without error")
    void startStopLifecycle() {
        cache = createCache(List.of(toggle("test", true)));
        cache.start();
        assertThat(cache.findByName("test")).isPresent();

        cache.stop();
        // stop is graceful — no exceptions thrown
    }

    private static Toggle toggle(String name, boolean enabled) {
        return new Toggle(UUID.randomUUID().toString(), "proj-1", name,
                Optional.empty(), List.of(new ToggleState("DEV", enabled)),
                Instant.now(), Optional.empty());
    }

    private PollingToggleCache createCache(List<Toggle> toggles) {
        TogliApiPort stubApi = new StubTogliApiPort(toggles);
        return new PollingToggleCache(stubApi, "proj-1", Duration.ofMinutes(60));
    }

    /**
     * Minimal stub of TogliApiPort for cache tests.
     */
    private static final class StubTogliApiPort implements TogliApiPort {

        private final List<Toggle> toggles;

        StubTogliApiPort(List<Toggle> toggles) {
            this.toggles = toggles;
        }

        @Override
        public ProjectInfo fetchProjectBySlug(String slug) {
            return new ProjectInfo("proj-1", slug, "Test", Optional.empty(),
                    false, Instant.now(), Optional.empty());
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
}
