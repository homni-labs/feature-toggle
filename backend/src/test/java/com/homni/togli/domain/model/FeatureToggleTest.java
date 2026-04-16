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

import java.time.Instant;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link FeatureToggle} aggregate.
 *
 * <p>Every test run uses randomized data: names, descriptions, environment
 * sets and timestamps are generated fresh. This ensures tests verify real
 * invariants rather than passing by coincidence with hardcoded values.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("FeatureToggle")
class FeatureToggleTest {

    @Nested
    @DisplayName("creation")
    class Creation {

        @Test
        @DisplayName("succeeds with valid name and environments present in project")
        void succeedsWithValidData() {
            ProjectId projectId = new ProjectId();
            String name = randomName();
            String description = randomDescription();
            Set<String> projectEnvs = randomEnvSet(4);
            Set<String> toggleEnvs = randomSubset(projectEnvs);

            FeatureToggle toggle = new FeatureToggle(projectId, name, description, toggleEnvs, projectEnvs);

            assertThat(toggle.id).isNotNull();
            assertThat(toggle.projectId).isEqualTo(projectId);
            assertThat(toggle.name()).isEqualTo(name);
            assertThat(toggle.description()).contains(description);
            assertThat(toggle.environments()).containsExactlyInAnyOrderElementsOf(toggleEnvs);
            assertThat(toggle.createdAt).isNotNull();
            assertThat(toggle.lastModifiedAt()).isEmpty();
        }

        @Test
        @DisplayName("all environments start disabled regardless of count")
        void allEnvironmentsStartDisabled() {
            Set<String> projectEnvs = randomEnvSet(5);
            Set<String> toggleEnvs = randomSubset(projectEnvs);

            FeatureToggle toggle = new FeatureToggle(new ProjectId(), randomName(), null, toggleEnvs, projectEnvs);

            for (String env : toggleEnvs) {
                assertThat(toggle.isEnabledIn(env)).isFalse();
            }
        }

        @Test
        @DisplayName("rejects blank name")
        void rejectsBlankName() {
            Set<String> projectEnvs = randomEnvSet(2);

            assertThatThrownBy(() -> new FeatureToggle(
                    new ProjectId(), "  ", null, projectEnvs, projectEnvs))
                    .isInstanceOf(DomainValidationException.class);
        }

        @Test
        @DisplayName("rejects name exceeding 255 characters")
        void rejectsNameExceeding255Characters() {
            String longName = randomName() + "x".repeat(256);
            Set<String> projectEnvs = randomEnvSet(2);

            assertThatThrownBy(() -> new FeatureToggle(
                    new ProjectId(), longName, null, projectEnvs, projectEnvs))
                    .isInstanceOf(DomainValidationException.class);
        }

        @Test
        @DisplayName("rejects empty environment set")
        void rejectsEmptyEnvironments() {
            assertThatThrownBy(() -> new FeatureToggle(
                    new ProjectId(), randomName(), null, Set.of(), randomEnvSet(3)))
                    .isInstanceOf(DomainValidationException.class);
        }

        @Test
        @DisplayName("rejects environment not present in project")
        void rejectsEnvironmentNotInProject() {
            Set<String> projectEnvs = randomEnvSet(2);
            String alien = "ALIEN_" + randomSuffix();

            assertThatThrownBy(() -> new FeatureToggle(
                    new ProjectId(), randomName(), null,
                    Set.of(alien), projectEnvs))
                    .isInstanceOf(DomainValidationException.class)
                    .hasMessageContaining(alien);
        }
    }

    @Nested
    @DisplayName("setEnvironmentStates")
    class SetEnvironmentStates {

        @Test
        @DisplayName("enables an environment and bumps updatedAt")
        void enablesEnvironment() {
            Set<String> envs = randomEnvSet(3);
            FeatureToggle toggle = newToggle(envs);
            String target = envs.iterator().next();

            toggle.setEnvironmentStates(Map.of(target, true));

            assertThat(toggle.isEnabledIn(target)).isTrue();
            assertThat(toggle.lastModifiedAt()).isPresent();
        }

        @Test
        @DisplayName("disables a previously enabled environment")
        void disablesPreviouslyEnabled() {
            Set<String> envs = randomEnvSet(2);
            FeatureToggle toggle = newToggle(envs);
            String target = envs.iterator().next();
            toggle.setEnvironmentStates(Map.of(target, true));

            toggle.setEnvironmentStates(Map.of(target, false));

            assertThat(toggle.isEnabledIn(target)).isFalse();
        }

        @Test
        @DisplayName("skips no-op and does not bump updatedAt")
        void skipsNoOpChange() {
            Set<String> envs = randomEnvSet(2);
            FeatureToggle toggle = newToggle(envs);
            String target = envs.iterator().next();

            toggle.setEnvironmentStates(Map.of(target, false));

            assertThat(toggle.lastModifiedAt()).isEmpty();
        }

        @Test
        @DisplayName("null input is a no-op")
        void nullInputIsNoOp() {
            FeatureToggle toggle = newToggle(randomEnvSet(2));

            toggle.setEnvironmentStates(null);

            assertThat(toggle.lastModifiedAt()).isEmpty();
        }

        @Test
        @DisplayName("applies batch of changes to multiple environments at once")
        void appliesBatchChanges() {
            Set<String> envs = randomEnvSet(3);
            FeatureToggle toggle = newToggle(envs);
            Iterator<String> iter = envs.iterator();
            String first = iter.next();
            String second = iter.next();

            toggle.setEnvironmentStates(Map.of(first, true, second, true));

            assertThat(toggle.isEnabledIn(first)).isTrue();
            assertThat(toggle.isEnabledIn(second)).isTrue();
        }

        @Test
        @DisplayName("rejects environment not assigned to toggle")
        void rejectsUnassignedEnvironment() {
            Set<String> projectEnvs = randomEnvSet(3);
            Set<String> toggleEnvs = Set.of(projectEnvs.iterator().next());
            FeatureToggle toggle = new FeatureToggle(
                    new ProjectId(), randomName(), null, toggleEnvs, projectEnvs);

            String unassigned = projectEnvs.stream()
                    .filter(e -> !toggleEnvs.contains(e))
                    .findFirst().orElseThrow();

            assertThatThrownBy(() -> toggle.setEnvironmentStates(Map.of(unassigned, true)))
                    .isInstanceOf(DomainValidationException.class)
                    .hasMessageContaining(unassigned);
        }
    }

    @Nested
    @DisplayName("update")
    class Update {

        @Test
        @DisplayName("adding new environment starts it as disabled and preserves existing state")
        void addingNewEnvironmentStartsDisabled() {
            Set<String> projectEnvs = randomEnvSet(4);
            Iterator<String> iter = projectEnvs.iterator();
            String existing = iter.next();
            String added = iter.next();
            FeatureToggle toggle = new FeatureToggle(
                    new ProjectId(), randomName(), null, Set.of(existing), projectEnvs);
            toggle.setEnvironmentStates(Map.of(existing, true));

            toggle.update(null, null, Set.of(existing, added), projectEnvs);

            assertThat(toggle.isEnabledIn(existing)).isTrue();
            assertThat(toggle.isEnabledIn(added)).isFalse();
            assertThat(toggle.environments()).containsExactlyInAnyOrder(existing, added);
        }

        @Test
        @DisplayName("removing environment drops its state but preserves remaining")
        void removingEnvironmentDropsState() {
            Set<String> projectEnvs = randomEnvSet(3);
            FeatureToggle toggle = newToggle(projectEnvs);
            Iterator<String> iter = projectEnvs.iterator();
            String kept = iter.next();
            String removed = iter.next();
            toggle.setEnvironmentStates(Map.of(kept, true, removed, true));

            Set<String> remaining = projectEnvs.stream()
                    .filter(e -> !e.equals(removed))
                    .collect(Collectors.toUnmodifiableSet());
            toggle.update(null, null, remaining, projectEnvs);

            assertThat(toggle.environments()).doesNotContain(removed);
            assertThat(toggle.isEnabledIn(kept)).isTrue();
        }

        @Test
        @DisplayName("renames toggle")
        void renamesToggles() {
            Set<String> envs = randomEnvSet(2);
            FeatureToggle toggle = newToggle(envs);
            String newName = randomName();

            toggle.update(newName, null, null, null);

            assertThat(toggle.name()).isEqualTo(newName);
            assertThat(toggle.lastModifiedAt()).isPresent();
        }

        @Test
        @DisplayName("rejects new environments not present in project")
        void rejectsNewEnvironmentsNotInProject() {
            Set<String> projectEnvs = randomEnvSet(2);
            FeatureToggle toggle = newToggle(projectEnvs);
            String alien = "ALIEN_" + randomSuffix();

            assertThatThrownBy(() -> toggle.update(null, null, Set.of(alien), projectEnvs))
                    .isInstanceOf(DomainValidationException.class)
                    .hasMessageContaining(alien);
        }

        @Test
        @DisplayName("all-null parameters are a no-op — updatedAt stays empty")
        void allNullParametersAreNoOp() {
            FeatureToggle toggle = newToggle(randomEnvSet(2));

            toggle.update(null, null, null, null);

            assertThat(toggle.lastModifiedAt()).isEmpty();
        }
    }

    @Nested
    @DisplayName("isEnabledIn")
    class IsEnabledIn {

        @Test
        @DisplayName("returns false for environment not assigned to toggle")
        void returnsFalseForUnknownEnvironment() {
            FeatureToggle toggle = newToggle(randomEnvSet(2));

            assertThat(toggle.isEnabledIn("NONEXISTENT_" + randomSuffix())).isFalse();
        }
    }

    @Nested
    @DisplayName("reconstitution")
    class Reconstitution {

        @Test
        @DisplayName("preserves all fields from storage")
        void preservesAllFields() {
            FeatureToggleId id = new FeatureToggleId();
            ProjectId projectId = new ProjectId();
            String name = randomName();
            String description = randomDescription();
            Instant createdAt = randomPastInstant();
            Instant updatedAt = Instant.now();
            String envA = "ENV_" + randomSuffix();
            String envB = "ENV_" + randomSuffix();

            FeatureToggle toggle = new FeatureToggle(
                    id, projectId, name, description,
                    Map.of(envA, true, envB, false),
                    createdAt, updatedAt);

            assertThat(toggle.id).isEqualTo(id);
            assertThat(toggle.projectId).isEqualTo(projectId);
            assertThat(toggle.name()).isEqualTo(name);
            assertThat(toggle.description()).contains(description);
            assertThat(toggle.isEnabledIn(envA)).isTrue();
            assertThat(toggle.isEnabledIn(envB)).isFalse();
            assertThat(toggle.createdAt).isEqualTo(createdAt);
            assertThat(toggle.lastModifiedAt()).contains(updatedAt);
        }
    }

    private static FeatureToggle newToggle(Set<String> envs) {
        return new FeatureToggle(new ProjectId(), randomName(), null, envs, envs);
    }
}