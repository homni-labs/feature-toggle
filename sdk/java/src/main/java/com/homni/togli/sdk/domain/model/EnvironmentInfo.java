/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

import java.time.Instant;
import java.util.Objects;

/**
 * Read-only summary of a project environment.
 *
 * @param id        unique identifier, must not be {@code null}
 * @param projectId identifier of the owning project, must not be {@code null}
 * @param name      human-readable environment name, must not be {@code null}
 * @param createdAt creation timestamp, must not be {@code null}
 */
public record EnvironmentInfo(String id, String projectId, String name, Instant createdAt) {

    /**
     * Creates a new environment info after validating invariants.
     */
    public EnvironmentInfo {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(projectId, "projectId must not be null");
        Objects.requireNonNull(name, "name must not be null");
        Objects.requireNonNull(createdAt, "createdAt must not be null");
    }
}
