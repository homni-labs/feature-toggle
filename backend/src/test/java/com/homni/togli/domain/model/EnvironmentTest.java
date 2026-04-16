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
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link Environment} entity and its shared
 * {@code validateAndNormalize} method.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("Environment")
class EnvironmentTest {

    @Nested
    @DisplayName("validateAndNormalize")
    class ValidateAndNormalize {

        @Test
        @DisplayName("normalizes to uppercase and trims whitespace")
        void normalizesToUppercase() {
            String result = Environment.validateAndNormalize("  dev  ");

            assertThat(result).isEqualTo("DEV");
        }

        @Test
        @DisplayName("accepts letters, digits and underscores")
        void acceptsValidCharacters() {
            String name = "STAGE_2_EU";

            assertThat(Environment.validateAndNormalize(name)).isEqualTo("STAGE_2_EU");
        }

        @Test
        @DisplayName("rejects blank name")
        void rejectsBlank() {
            assertThatThrownBy(() -> Environment.validateAndNormalize("  "))
                    .isInstanceOf(DomainValidationException.class);
        }

        @Test
        @DisplayName("rejects name exceeding 50 characters")
        void rejectsTooLong() {
            String longName = "A" + "B".repeat(50);

            assertThatThrownBy(() -> Environment.validateAndNormalize(longName))
                    .isInstanceOf(DomainValidationException.class);
        }

        @Test
        @DisplayName("rejects name starting with digit")
        void rejectsStartingWithDigit() {
            assertThatThrownBy(() -> Environment.validateAndNormalize("1INVALID"))
                    .isInstanceOf(DomainValidationException.class);
        }

        @Test
        @DisplayName("rejects name containing hyphens")
        void rejectsHyphens() {
            assertThatThrownBy(() -> Environment.validateAndNormalize("DEV-EU"))
                    .isInstanceOf(DomainValidationException.class);
        }
    }

    @Nested
    @DisplayName("creation")
    class Creation {

        @Test
        @DisplayName("creates environment with normalized name")
        void createsWithNormalizedName() {
            Environment env = new Environment(new ProjectId(), "staging");

            assertThat(env.id).isNotNull();
            assertThat(env.name()).isEqualTo("STAGING");
            assertThat(env.createdAt).isNotNull();
        }
    }
}
