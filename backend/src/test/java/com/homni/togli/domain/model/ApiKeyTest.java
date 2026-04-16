/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.InvalidStateException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link ApiKey} aggregate.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("ApiKey")
class ApiKeyTest {

    @Nested
    @DisplayName("creation")
    class Creation {

        @Test
        @DisplayName("new key is active")
        void newKeyIsActive() {
            ApiKey key = newApiKey(null);

            assertThat(key.id).isNotNull();
            assertThat(key.isActive()).isTrue();
            assertThat(key.isValid()).isTrue();
        }
    }

    @Nested
    @DisplayName("revoke")
    class Revoke {

        @Test
        @DisplayName("revokes an active key")
        void revokesActiveKey() {
            ApiKey key = newApiKey(null);

            key.revoke();

            assertThat(key.isActive()).isFalse();
            assertThat(key.isValid()).isFalse();
        }

        @Test
        @DisplayName("rejects revoking already revoked key")
        void rejectsDoubleRevoke() {
            ApiKey key = newApiKey(null);
            key.revoke();

            assertThatThrownBy(key::revoke)
                    .isInstanceOf(InvalidStateException.class);
        }
    }

    @Nested
    @DisplayName("isValid")
    class IsValid {

        @Test
        @DisplayName("valid when active and expiration in the future")
        void validWithFutureExpiration() {
            Instant futureExpiry = Instant.now().plus(30, ChronoUnit.DAYS);
            ApiKey key = newApiKey(futureExpiry);

            assertThat(key.isValid()).isTrue();
        }

        @Test
        @DisplayName("invalid when active but expiration in the past")
        void invalidWithPastExpiration() {
            Instant pastExpiry = Instant.now().minus(1, ChronoUnit.DAYS);
            ApiKey key = newApiKey(pastExpiry);

            assertThat(key.isValid()).isFalse();
        }

        @Test
        @DisplayName("valid when active and no expiration set")
        void validWithNoExpiration() {
            ApiKey key = newApiKey(null);

            assertThat(key.isValid()).isTrue();
        }
    }

    @Nested
    @DisplayName("maskedToken")
    class MaskedToken {

        @Test
        @DisplayName("masks token hash preserving only last 4 characters")
        void masksTokenHash() {
            ApiKey key = newApiKey(null);

            String masked = key.maskedToken();

            assertThat(masked).startsWith("hft_****");
            assertThat(masked).hasSize("hft_****".length() + 4);
        }
    }

    private static ApiKey newApiKey(Instant expiresAt) {
        TokenHash hash = TokenHash.from(UUID.randomUUID().toString());
        return new ApiKey(new ProjectId(), randomName(), ProjectRole.READER, hash, expiresAt);
    }
}
