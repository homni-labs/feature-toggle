/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.model;

import com.homni.featuretoggle.domain.exception.DomainValidationException;
import com.homni.featuretoggle.domain.exception.InvalidStateException;

import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

/**
 * Feature toggle scoped to a project, assigned to one or more environments.
 */
public final class FeatureToggle {

    public final FeatureToggleId id;
    public final ProjectId projectId;
    public final Instant createdAt;

    private String name;
    private String description;
    private boolean enabled;
    private Instant updatedAt;
    private final Set<String> environments;

    /**
     * Creates a new disabled toggle within a project.
     *
     * @param projectId    the owning project
     * @param name         toggle name (1-255 chars)
     * @param description  optional description
     * @param environments initial environments, non-empty
     * @throws DomainValidationException if name or environments invalid
     */
    public FeatureToggle(ProjectId projectId, String name, String description,
                         Set<String> environments) {
        this.id = new FeatureToggleId();
        this.projectId = Objects.requireNonNull(projectId);
        this.name = validateName(name);
        this.description = description;
        this.enabled = false;
        this.environments = validateEnvironments(name, environments);
        this.createdAt = Instant.now();
        this.updatedAt = null;
    }

    /**
     * Reconstitutes from storage.
     *
     * @param id           the toggle identity
     * @param projectId    the owning project
     * @param name         the toggle name
     * @param description  optional description
     * @param enabled      enabled flag
     * @param environments assigned environment names
     * @param createdAt    creation timestamp
     * @param updatedAt    last modification timestamp
     * @throws DomainValidationException if name or environments invalid
     */
    public FeatureToggle(FeatureToggleId id, ProjectId projectId, String name,
                         String description, boolean enabled, Set<String> environments,
                         Instant createdAt, Instant updatedAt) {
        this.id = Objects.requireNonNull(id);
        this.projectId = Objects.requireNonNull(projectId);
        this.name = validateName(name);
        this.description = description;
        this.enabled = enabled;
        this.environments = validateEnvironments(name, environments);
        this.createdAt = Objects.requireNonNull(createdAt);
        this.updatedAt = updatedAt;
    }

    /**
     * Enables this toggle.
     *
     * @return this toggle for chaining
     * @throws InvalidStateException if already enabled
     */
    public FeatureToggle enable() {
        if (this.enabled) {
            throw new InvalidStateException("Toggle [id=%s, name=%s] is already enabled".formatted(this.id.value, this.name));
        }
        this.enabled = true;
        this.updatedAt = Instant.now();
        return this;
    }

    /**
     * Disables this toggle.
     *
     * @return this toggle for chaining
     * @throws InvalidStateException if already disabled
     */
    public FeatureToggle disable() {
        if (!this.enabled) {
            throw new InvalidStateException("Toggle [id=%s, name=%s] is already disabled".formatted(this.id.value, this.name));
        }
        this.enabled = false;
        this.updatedAt = Instant.now();
        return this;
    }

    /**
     * Updates mutable fields; {@code null} parameters are skipped.
     *
     * @param newName         new name, or {@code null}
     * @param newDescription  new description, or {@code null}
     * @param newEnvironments new environments, or {@code null}
     * @throws DomainValidationException if name or environments invalid
     */
    public void update(String newName, String newDescription, Set<String> newEnvironments) {
        if (newName == null && newDescription == null && newEnvironments == null) {
            return;
        }
        if (newName != null) {
            this.name = validateName(newName);
        }
        if (newDescription != null) {
            this.description = newDescription;
        }
        if (newEnvironments != null) {
            LinkedHashSet<String> validated = validateEnvironments(this.name, newEnvironments);
            this.environments.clear();
            this.environments.addAll(validated);
        }
        this.updatedAt = Instant.now();
    }

    /**
     * Current toggle name.
     *
     * @return the toggle name
     */
    public String name() {
        return this.name;
    }

    /**
     * Toggle description.
     *
     * @return the description, or empty
     */
    public Optional<String> description() {
        return Optional.ofNullable(this.description);
    }

    /**
     * Whether this toggle is enabled.
     *
     * @return {@code true} if enabled
     */
    public boolean isEnabled() {
        return this.enabled;
    }

    /**
     * Assigned environment names (immutable copy).
     *
     * @return the environment names
     */
    public Set<String> environments() {
        return Set.copyOf(this.environments);
    }

    /**
     * Last modification timestamp.
     *
     * @return the timestamp, or empty if never modified
     */
    public Optional<Instant> lastModifiedAt() {
        return Optional.ofNullable(this.updatedAt);
    }

    private LinkedHashSet<String> validateEnvironments(String toggleName,
                                                       Set<String> environments) {
        if (environments == null || environments.isEmpty()) {
            throw new DomainValidationException("Toggle '%s' must have at least one environment".formatted(toggleName));
        }
        return new LinkedHashSet<>(environments);
    }

    private String validateName(String name) {
        if (name == null || name.isBlank() || name.length() > 255) {
            throw new DomainValidationException("Invalid toggle name: " + name);
        }
        return name;
    }
}
