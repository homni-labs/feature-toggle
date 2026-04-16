/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.DomainValidationException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link Email} value object.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("Email")
class EmailTest {

    @Test
    @DisplayName("accepts valid email and normalizes to lowercase")
    void acceptsValidEmail() {
        String raw = randomEmail().toUpperCase();

        Email email = new Email(raw);

        assertThat(email.value()).isEqualTo(raw.toLowerCase());
    }

    @Test
    @DisplayName("rejects invalid format")
    void rejectsInvalidFormat() {
        assertThatThrownBy(() -> new Email("not-an-email"))
                .isInstanceOf(DomainValidationException.class);
    }

    @Test
    @DisplayName("rejects blank string")
    void rejectsBlank() {
        assertThatThrownBy(() -> new Email("  "))
                .isInstanceOf(DomainValidationException.class);
    }

    @Test
    @DisplayName("rejects null")
    void rejectsNull() {
        assertThatThrownBy(() -> new Email(null))
                .isInstanceOf(DomainValidationException.class);
    }
}
