/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("TogliConfiguration")
class TogliConfigurationTest {

    @Nested
    @DisplayName("defaults")
    class Defaults {

        @Test
        @DisplayName("applies default values for optional fields")
        void appliesDefaults() {
            TogliConfiguration config = new TogliConfiguration(
                    "http://localhost:8080", "api-key-" + UUID.randomUUID(),
                    "my-project", "my-service");

            assertThat(config.pollingInterval).isEqualTo(Duration.ofMinutes(60));
            assertThat(config.requestTimeout).isEqualTo(Duration.ofSeconds(10));
            assertThat(config.connectTimeout).isEqualTo(Duration.ofSeconds(5));
            assertThat(config.cacheEnabled).isTrue();
            assertThat(config.eagerInit).isTrue();
            assertThat(config.errorListener).isNull();
            assertThat(config.defaultEnvironment).isNull();
        }
    }

    @Nested
    @DisplayName("validation")
    class Validation {

        @Test
        @DisplayName("rejects blank baseUrl")
        void rejectsBlankBaseUrl() {
            assertThatThrownBy(() -> new TogliConfiguration("  ", "key", "slug", "svc"))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("rejects null apiKey")
        void rejectsNullApiKey() {
            assertThatThrownBy(() -> new TogliConfiguration("http://localhost", null, "slug", "svc"))
                    .isInstanceOf(NullPointerException.class);
        }

        @Test
        @DisplayName("rejects blank projectSlug")
        void rejectsBlankProjectSlug() {
            assertThatThrownBy(() -> new TogliConfiguration("http://localhost", "key", "  ", "svc"))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("rejects blank serviceName")
        void rejectsBlankServiceName() {
            assertThatThrownBy(() -> new TogliConfiguration("http://localhost", "key", "slug", "  "))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("rejects polling interval below 5 seconds when cache enabled")
        void rejectsShortPollingInterval() {
            assertThatThrownBy(() -> new TogliConfiguration(
                    "http://localhost", "key", "slug",
                    Duration.ofSeconds(2), null, null,
                    true, true, null, null, null, "svc", null))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("5 seconds");
        }

        @Test
        @DisplayName("allows short polling interval when cache disabled")
        void allowsShortPollingWhenCacheDisabled() {
            TogliConfiguration config = new TogliConfiguration(
                    "http://localhost", "key", "slug",
                    Duration.ofSeconds(1), null, null,
                    false, false, null, null, null, "svc", null);

            assertThat(config.pollingInterval).isEqualTo(Duration.ofSeconds(1));
        }
    }
}
