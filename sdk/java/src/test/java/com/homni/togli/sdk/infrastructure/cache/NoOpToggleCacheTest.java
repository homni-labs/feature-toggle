/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.cache;

import com.homni.togli.sdk.domain.model.Toggle;
import com.homni.togli.sdk.domain.model.ToggleState;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("NoOpToggleCache")
class NoOpToggleCacheTest {

    private final NoOpToggleCache cache = new NoOpToggleCache();

    @Test
    @DisplayName("findByName always returns empty")
    void findByNameReturnsEmpty() {
        assertThat(cache.findByName("any-toggle")).isEmpty();
    }

    @Test
    @DisplayName("all always returns empty list")
    void allReturnsEmpty() {
        assertThat(cache.all()).isEmpty();
    }

    @Test
    @DisplayName("refresh does not make toggles findable")
    void refreshIsNoOp() {
        Toggle toggle = new Toggle(UUID.randomUUID().toString(), UUID.randomUUID().toString(),
                "test", Optional.empty(), List.of(new ToggleState("DEV", true)),
                Instant.now(), Optional.empty());

        cache.refresh(List.of(toggle));

        assertThat(cache.findByName("test")).isEmpty();
        assertThat(cache.all()).isEmpty();
    }
}
