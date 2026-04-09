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

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

/**
 * Feature toggle scoped to a project. Each toggle is "present" in one or more
 * environments and carries an independent enabled flag per environment, so the
 * same toggle can be ON in DEV and OFF in PROD. The aggregate guarantees the
 * invariant that at least one environment is always present.
 */
public final class FeatureToggle {

    public final FeatureToggleId id;
    public final ProjectId projectId;
    public final Instant createdAt;

    private String name;
    private String description;
    private Instant updatedAt;
    /**
     * Mutable per-env state map. Iteration order is unspecified — keeping
     * the UI rendering order stable is the presenter's job, not the domain's.
     */
    private final HashMap<String, Boolean> environmentStates;

    /**
     * Creates a brand-new toggle. Every supplied environment starts disabled
     * — callers must explicitly turn it on per env afterwards. Each requested
     * environment must exist in the owning project, otherwise the creation
     * is rejected.
     *
     * @param projectId           owning project
     * @param name                toggle name (1-255 chars)
     * @param description         optional description
     * @param environments        initial environment names, non-empty
     * @param projectEnvironments names of all environments that exist in the owning project
     * @throws DomainValidationException if name is invalid, environments empty,
     *                                   or any requested env is not in the project
     */
    public FeatureToggle(ProjectId projectId, String name, String description,
                         Set<String> environments, Set<String> projectEnvironments) {
        this.id = new FeatureToggleId();
        this.projectId = Objects.requireNonNull(projectId);
        this.name = validateName(name);
        this.description = description;
        requireEnvsInProject(environments, projectEnvironments);
        this.environmentStates = validateAndBuildStates(this.name, environments);
        this.createdAt = Instant.now();
        this.updatedAt = null;
    }

    /**
     * Reconstitutes from storage.
     *
     * @param id                the toggle identity
     * @param projectId         the owning project
     * @param name              the toggle name
     * @param description       optional description
     * @param environmentStates per-environment enabled state, non-empty
     * @param createdAt         creation timestamp
     * @param updatedAt         last modification timestamp
     * @throws DomainValidationException if name or environments are invalid
     */
    public FeatureToggle(FeatureToggleId id, ProjectId projectId, String name,
                         String description, Map<String, Boolean> environmentStates,
                         Instant createdAt, Instant updatedAt) {
        this.id = Objects.requireNonNull(id);
        this.projectId = Objects.requireNonNull(projectId);
        this.name = validateName(name);
        this.description = description;
        this.environmentStates = validateAndCloneStates(name, environmentStates);
        this.createdAt = Objects.requireNonNull(createdAt);
        this.updatedAt = updatedAt;
    }

    /**
     * Applies a batch of per-environment enabled flag changes. Each entry is
     * validated against the toggle's current env set, no-op entries (where the
     * desired flag already matches) are skipped silently, and {@code updatedAt}
     * is bumped at most once for the whole batch. {@code null} or empty input
     * is a no-op.
     *
     * @param changes desired enabled flag per env name
     * @throws DomainValidationException if any env name is not assigned to this toggle
     */
    public void setEnvironmentStates(Map<String, Boolean> changes) {
        if (changes == null || changes.isEmpty()) {
            return;
        }
        boolean anyChanged = false;
        for (Map.Entry<String, Boolean> entry : changes.entrySet()) {
            String envName = entry.getKey();
            boolean desired = Boolean.TRUE.equals(entry.getValue());
            ensureEnvAssigned(envName);
            boolean current = Boolean.TRUE.equals(this.environmentStates.get(envName));
            if (current == desired) {
                continue;
            }
            this.environmentStates.put(envName, desired);
            anyChanged = true;
        }
        if (anyChanged) {
            this.updatedAt = Instant.now();
        }
    }

    /**
     * Updates mutable fields. {@code null} parameters are skipped.
     * <p>
     * When {@code newEnvironments} differs from the current set, environments
     * removed from the set are dropped along with their state, newly added
     * environments start disabled, and existing envs that are kept retain
     * their current enabled state. Each requested env must exist in the
     * owning project, otherwise the update is rejected.
     *
     * @param newName             new name, or {@code null} to keep
     * @param newDescription      new description, or {@code null} to keep
     * @param newEnvironments     new environment names, or {@code null} to keep
     * @param projectEnvironments names of all envs in the owning project; only
     *                            consulted when {@code newEnvironments} is non-null
     * @throws DomainValidationException if name or environments are invalid,
     *                                   or any requested env is not in the project
     */
    public void update(String newName, String newDescription,
                       Set<String> newEnvironments, Set<String> projectEnvironments) {
        if (newName == null && newDescription == null && newEnvironments == null) {
            return;
        }
        if (newName != null) {
            this.name = validateName(newName);
        }
        if (newDescription != null) {
            this.description = newDescription;
        }
        if (newEnvironments != null && !newEnvironments.isEmpty()) {
            requireEnvsInProject(newEnvironments, projectEnvironments);
            // Drop removed envs along with their state.
            this.environmentStates.keySet().retainAll(newEnvironments);
            // Add new envs as disabled. putIfAbsent preserves existing state.
            for (String env : newEnvironments) {
                this.environmentStates.putIfAbsent(env, false);
            }
            if (this.environmentStates.isEmpty()) {
                throw new DomainValidationException(
                        "Toggle '%s' must have at least one environment".formatted(this.name));
            }
        }
        this.updatedAt = Instant.now();
    }

    /**
     * Whether this toggle is enabled in a specific environment.
     *
     * @param envName environment name
     * @return {@code true} if enabled, {@code false} if disabled or not assigned
     */
    public boolean isEnabledIn(String envName) {
        return Boolean.TRUE.equals(this.environmentStates.get(envName));
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
     * Assigned environment names (immutable copy of the key set in insertion
     * order).
     *
     * @return the environment names
     */
    public Set<String> environments() {
        return Set.copyOf(this.environmentStates.keySet());
    }

    /**
     * Per-environment enabled state, immutable copy.
     *
     * @return the state map
     */
    public Map<String, Boolean> environmentStates() {
        return Map.copyOf(this.environmentStates);
    }

    /**
     * Last modification timestamp.
     *
     * @return the timestamp, or empty if never modified
     */
    public Optional<Instant> lastModifiedAt() {
        return Optional.ofNullable(this.updatedAt);
    }

    private void ensureEnvAssigned(String envName) {
        if (envName == null || !this.environmentStates.containsKey(envName)) {
            throw new DomainValidationException(
                    "Environment '%s' is not assigned to toggle '%s'".formatted(envName, this.name));
        }
    }

    /**
     * Validates that every requested env name exists in the owning project's
     * env set. Centralizes the rule so both creation and update enforce it
     * the same way, and so use cases can stay free of this check.
     */
    private static void requireEnvsInProject(Set<String> requested, Set<String> projectEnvironments) {
        if (requested == null || requested.isEmpty()) {
            return;
        }
        Objects.requireNonNull(projectEnvironments,
                "projectEnvironments must not be null when assigning environments");
        for (String env : requested) {
            if (!projectEnvironments.contains(env)) {
                throw new DomainValidationException(
                        "Environment '%s' does not exist in this project".formatted(env));
            }
        }
    }

    private HashMap<String, Boolean> validateAndBuildStates(String toggleName,
                                                                    Set<String> environments) {
        if (environments == null || environments.isEmpty()) {
            throw new DomainValidationException(
                    "Toggle '%s' must have at least one environment".formatted(toggleName));
        }
        HashMap<String, Boolean> states = new HashMap<>(environments.size());
        for (String env : environments) {
            states.put(env, false);
        }
        return states;
    }

    private HashMap<String, Boolean> validateAndCloneStates(String toggleName,
                                                                    Map<String, Boolean> source) {
        if (source == null || source.isEmpty()) {
            throw new DomainValidationException(
                    "Toggle '%s' must have at least one environment".formatted(toggleName));
        }
        return new HashMap<>(source);
    }

    private String validateName(String name) {
        if (name == null || name.isBlank() || name.length() > 255) {
            throw new DomainValidationException("Invalid toggle name: " + name);
        }
        return name;
    }
}
