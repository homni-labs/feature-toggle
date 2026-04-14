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

import java.time.Instant;
import java.util.Objects;

/**
 * Deployment environment scoped to a project, normalized to uppercase.
 */
public final class Environment {

    public final EnvironmentId id;
    public final ProjectId projectId;
    public final Instant createdAt;

    private String name;

    /**
     * Creates a new environment within a project.
     *
     * @param projectId the owning project
     * @param name      environment name (1-50 chars)
     * @throws DomainValidationException if name is invalid
     */
    public Environment(ProjectId projectId, String name) {
        this.id = new EnvironmentId();
        this.projectId = Objects.requireNonNull(projectId);
        this.name = validateAndNormalize(name);
        this.createdAt = Instant.now();
    }

    /**
     * Reconstitutes from storage.
     *
     * @param id        the environment identity
     * @param projectId the owning project
     * @param name      the environment name
     * @param createdAt creation timestamp
     * @throws DomainValidationException if name is invalid
     */
    public Environment(EnvironmentId id, ProjectId projectId, String name, Instant createdAt) {
        this.id = Objects.requireNonNull(id);
        this.projectId = Objects.requireNonNull(projectId);
        this.name = validateAndNormalize(name);
        this.createdAt = Objects.requireNonNull(createdAt);
    }

    /**
     * Uppercase environment name.
     *
     * @return the environment name
     */
    public String name() {
        return this.name;
    }

    /**
     * Validates and normalizes an environment name. Trimmed, uppercased, must be
     * 1-50 characters, must match {@code ^[A-Z][A-Z0-9_]*$}. Exposed as a static
     * helper so other domain types (e.g. {@link EnvironmentDefaults}) can reuse
     * the same rules without constructing a throwaway Environment instance.
     *
     * @param name raw input name
     * @return normalized name
     * @throws DomainValidationException if invalid
     */
    public static String validateAndNormalize(String name) {
        if (name == null || name.isBlank()) {
            throw new DomainValidationException("Invalid environment name '%s': must not be blank".formatted(name));
        }
        String normalized = name.trim().toUpperCase();
        if (normalized.length() > 50) {
            throw new DomainValidationException("Invalid environment name '%s': must not exceed 50 characters".formatted(name));
        }
        if (!normalized.matches("^[A-Z][A-Z0-9_]*$")) {
            throw new DomainValidationException("Invalid environment name '%s': must start with a letter and contain only letters, digits, and underscores".formatted(name));
        }
        return normalized;
    }
}
