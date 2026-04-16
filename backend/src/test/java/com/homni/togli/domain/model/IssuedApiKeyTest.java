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

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for the {@link IssuedApiKey} domain object.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("IssuedApiKey")
class IssuedApiKeyTest {

    @Test
    @DisplayName("generates token with hft_ prefix")
    void generatesTokenWithPrefix() {
        IssuedApiKey issued = new IssuedApiKey(new ProjectId(), randomName(), null);

        assertThat(issued.rawToken).startsWith("hft_");
    }

    @Test
    @DisplayName("apiKey tokenHash matches hash of rawToken")
    void tokenHashMatchesRawToken() {
        IssuedApiKey issued = new IssuedApiKey(new ProjectId(), randomName(), null);

        TokenHash expected = TokenHash.from(issued.rawToken);

        assertThat(issued.apiKey.tokenHash).isEqualTo(expected);
    }
}
