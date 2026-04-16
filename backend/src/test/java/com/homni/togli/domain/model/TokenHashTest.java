/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for the {@link TokenHash} value object.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("TokenHash")
class TokenHashTest {

    @Test
    @DisplayName("same input produces same hash (deterministic)")
    void deterministicHash() {
        String token = "hft_" + UUID.randomUUID();

        TokenHash first = TokenHash.from(token);
        TokenHash second = TokenHash.from(token);

        assertThat(first).isEqualTo(second);
        assertThat(first.value).isEqualTo(second.value);
    }

    @Test
    @DisplayName("different inputs produce different hashes")
    void differentInputsDifferentHashes() {
        TokenHash first = TokenHash.from("hft_" + UUID.randomUUID());
        TokenHash second = TokenHash.from("hft_" + UUID.randomUUID());

        assertThat(first).isNotEqualTo(second);
    }
}
