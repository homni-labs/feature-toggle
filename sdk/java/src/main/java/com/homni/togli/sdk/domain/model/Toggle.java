/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * A feature toggle with its per-environment state.
 *
 * <p>Instances are immutable; the {@link #environments} list is a defensive copy.
 */
public final class Toggle {

    /** Unique identifier (UUID string). */
    public final String id;

    /** Identifier of the project this toggle belongs to. */
    public final String projectId;

    /** Human-readable toggle name. */
    public final String name;

    /** Optional description of the toggle's purpose. */
    public final Optional<String> description;

    /** Per-environment state (unmodifiable). */
    public final List<ToggleState> environments;

    /** Timestamp when this toggle was created. */
    public final Instant createdAt;

    /** Timestamp of the last update, or empty if never updated. */
    public final Optional<Instant> updatedAt;

    /**
     * Creates a new toggle.
     *
     * @param id           unique identifier, must not be {@code null} or blank
     * @param projectId    project identifier, must not be {@code null} or blank
     * @param name         toggle name, must not be {@code null} or blank
     * @param description  optional description (may be {@code null} or empty {@link Optional})
     * @param environments per-environment states, must not be {@code null}
     * @param createdAt    creation timestamp, must not be {@code null}
     * @param updatedAt    last-update timestamp (may be {@code null} or empty {@link Optional})
     */
    public Toggle(
            String id,
            String projectId,
            String name,
            Optional<String> description,
            List<ToggleState> environments,
            Instant createdAt,
            Optional<Instant> updatedAt
    ) {
        Objects.requireNonNull(id, "id must not be null");
        if (id.isBlank()) {
            throw new IllegalArgumentException("id must not be blank");
        }
        Objects.requireNonNull(projectId, "projectId must not be null");
        if (projectId.isBlank()) {
            throw new IllegalArgumentException("projectId must not be blank");
        }
        Objects.requireNonNull(name, "name must not be null");
        if (name.isBlank()) {
            throw new IllegalArgumentException("name must not be blank");
        }
        Objects.requireNonNull(environments, "environments must not be null");
        Objects.requireNonNull(createdAt, "createdAt must not be null");

        this.id = id;
        this.projectId = projectId;
        this.name = name;
        this.description = description == null ? Optional.empty() : description;
        this.environments = List.copyOf(environments);
        this.createdAt = createdAt;
        this.updatedAt = updatedAt == null ? Optional.empty() : updatedAt;
    }

    /**
     * Checks whether this toggle is enabled in the given environment.
     *
     * @param environmentName the environment name to look up, must not be {@code null}
     * @return {@code true} if the toggle is enabled in that environment,
     *         {@code false} if disabled or if the environment is not found
     */
    public boolean isEnabledIn(String environmentName) {
        Objects.requireNonNull(environmentName, "environmentName must not be null");
        return environments.stream()
                .filter(s -> s.environmentName().equals(environmentName))
                .findFirst()
                .map(ToggleState::enabled)
                .orElse(false);
    }

    /**
     * Returns the {@link ToggleState} for the given environment, if present.
     *
     * @param environmentName the environment name to look up, must not be {@code null}
     * @return the toggle state, or {@link Optional#empty()} if not found
     */
    public Optional<ToggleState> stateIn(String environmentName) {
        Objects.requireNonNull(environmentName, "environmentName must not be null");
        return environments.stream()
                .filter(s -> s.environmentName().equals(environmentName))
                .findFirst();
    }
}
