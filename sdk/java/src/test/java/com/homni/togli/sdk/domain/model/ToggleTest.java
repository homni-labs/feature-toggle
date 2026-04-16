/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("Toggle")
class ToggleTest {

    @Nested
    @DisplayName("creation")
    class Creation {

        @Test
        @DisplayName("succeeds with valid data")
        void succeedsWithValidData() {
            String id = UUID.randomUUID().toString();
            String name = "toggle-" + UUID.randomUUID().toString().substring(0, 8);
            ToggleState state = new ToggleState("DEV", true);

            Toggle toggle = new Toggle(id, UUID.randomUUID().toString(), name,
                    Optional.of("desc"), List.of(state), Instant.now(), Optional.empty());

            assertThat(toggle.id).isEqualTo(id);
            assertThat(toggle.name).isEqualTo(name);
            assertThat(toggle.description).contains("desc");
            assertThat(toggle.environments).hasSize(1);
            assertThat(toggle.updatedAt).isEmpty();
        }

        @Test
        @DisplayName("rejects blank id")
        void rejectsBlankId() {
            assertThatThrownBy(() -> new Toggle("  ", "proj", "name",
                    Optional.empty(), List.of(), Instant.now(), Optional.empty()))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("rejects blank name")
        void rejectsBlankName() {
            assertThatThrownBy(() -> new Toggle("id", "proj", "  ",
                    Optional.empty(), List.of(), Instant.now(), Optional.empty()))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("null description becomes empty Optional")
        void nullDescriptionBecomesEmpty() {
            Toggle toggle = new Toggle("id", "proj", "name",
                    null, List.of(), Instant.now(), Optional.empty());

            assertThat(toggle.description).isEmpty();
        }

        @Test
        @DisplayName("environments list is a defensive copy")
        void environmentsAreDefensiveCopy() {
            List<ToggleState> original = new java.util.ArrayList<>();
            original.add(new ToggleState("DEV", true));

            Toggle toggle = new Toggle("id", "proj", "name",
                    Optional.empty(), original, Instant.now(), Optional.empty());

            original.add(new ToggleState("PROD", false));
            assertThat(toggle.environments).hasSize(1);
        }
    }

    @Nested
    @DisplayName("isEnabledIn")
    class IsEnabledIn {

        @Test
        @DisplayName("returns true for enabled environment")
        void returnsTrueForEnabled() {
            Toggle toggle = toggleWith(new ToggleState("DEV", true), new ToggleState("PROD", false));

            assertThat(toggle.isEnabledIn("DEV")).isTrue();
        }

        @Test
        @DisplayName("returns false for disabled environment")
        void returnsFalseForDisabled() {
            Toggle toggle = toggleWith(new ToggleState("DEV", true), new ToggleState("PROD", false));

            assertThat(toggle.isEnabledIn("PROD")).isFalse();
        }

        @Test
        @DisplayName("returns false for unknown environment")
        void returnsFalseForUnknown() {
            Toggle toggle = toggleWith(new ToggleState("DEV", true));

            assertThat(toggle.isEnabledIn("NONEXISTENT")).isFalse();
        }
    }

    @Nested
    @DisplayName("stateIn")
    class StateIn {

        @Test
        @DisplayName("returns state for existing environment")
        void returnsStateForExisting() {
            Toggle toggle = toggleWith(new ToggleState("DEV", true));

            Optional<ToggleState> state = toggle.stateIn("DEV");

            assertThat(state).isPresent();
            assertThat(state.get().enabled()).isTrue();
        }

        @Test
        @DisplayName("returns empty for unknown environment")
        void returnsEmptyForUnknown() {
            Toggle toggle = toggleWith(new ToggleState("DEV", true));

            assertThat(toggle.stateIn("PROD")).isEmpty();
        }
    }

    private static Toggle toggleWith(ToggleState... states) {
        return new Toggle(UUID.randomUUID().toString(), UUID.randomUUID().toString(),
                "toggle-" + UUID.randomUUID().toString().substring(0, 6),
                Optional.empty(), List.of(states), Instant.now(), Optional.empty());
    }
}
