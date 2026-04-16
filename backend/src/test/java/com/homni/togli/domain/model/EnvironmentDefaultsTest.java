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

import java.util.List;

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link EnvironmentDefaults} value object.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("EnvironmentDefaults")
class EnvironmentDefaultsTest {

    @Nested
    @DisplayName("bootstrapFor")
    class BootstrapFor {

        @Test
        @DisplayName("null selection bootstraps all configured defaults")
        void nullSelectionBootstrapsAll() {
            String envA = "ENV_" + randomSuffix();
            String envB = "ENV_" + randomSuffix();
            EnvironmentDefaults defaults = new EnvironmentDefaults(List.of(envA, envB));
            ProjectId projectId = new ProjectId();

            List<Environment> result = defaults.bootstrapFor(projectId, null);

            assertThat(result).hasSize(2);
            assertThat(result).extracting(Environment::name)
                    .containsExactly(envA, envB);
        }

        @Test
        @DisplayName("empty selection creates no environments")
        void emptySelectionCreatesNone() {
            EnvironmentDefaults defaults = new EnvironmentDefaults(List.of("DEV", "PROD"));

            List<Environment> result = defaults.bootstrapFor(new ProjectId(), List.of());

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("explicit selection overrides defaults")
        void explicitSelectionOverrides() {
            String envA = "ENV_" + randomSuffix();
            String envB = "ENV_" + randomSuffix();
            EnvironmentDefaults defaults = new EnvironmentDefaults(List.of(envA, envB));

            List<Environment> result = defaults.bootstrapFor(new ProjectId(), List.of(envA));

            assertThat(result).hasSize(1);
            assertThat(result.getFirst().name()).isEqualTo(envA);
        }

        @Test
        @DisplayName("rejects selection not in configured defaults")
        void rejectsUnknownSelection() {
            EnvironmentDefaults defaults = new EnvironmentDefaults(List.of("DEV", "PROD"));
            String alien = "ALIEN_" + randomSuffix();

            assertThatThrownBy(() -> defaults.bootstrapFor(new ProjectId(), List.of(alien)))
                    .isInstanceOf(DomainValidationException.class)
                    .hasMessageContaining(alien);
        }
    }

    @Nested
    @DisplayName("construction")
    class Construction {

        @Test
        @DisplayName("deduplicates environment names")
        void rejectsDuplicates() {
            String env = "ENV_" + randomSuffix();

            assertThatThrownBy(() -> new EnvironmentDefaults(List.of(env, env)))
                    .isInstanceOf(DomainValidationException.class)
                    .hasMessageContaining("Duplicate");
        }

        @Test
        @DisplayName("normalizes names to uppercase")
        void normalizesToUppercase() {
            EnvironmentDefaults defaults = new EnvironmentDefaults(List.of("dev", "prod"));

            assertThat(defaults.all()).containsExactly("DEV", "PROD");
        }
    }
}
