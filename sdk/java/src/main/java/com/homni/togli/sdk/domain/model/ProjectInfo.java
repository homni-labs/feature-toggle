/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.Optional;

/**
 * Read-only summary of a Togli project.
 */
public final class ProjectInfo {

    /** Unique project identifier. */
    public final String id;

    /** URL-friendly project slug. */
    public final String slug;

    /** Human-readable project name. */
    public final String name;

    /** Optional description of the project. */
    public final Optional<String> description;

    /** Whether the project has been archived. */
    public final boolean archived;

    /** Timestamp when the project was created. */
    public final Instant createdAt;

    /** Timestamp of the last update, or empty if never updated. */
    public final Optional<Instant> updatedAt;

    /**
     * Creates a new project info.
     *
     * @param id          unique identifier, must not be {@code null} or blank
     * @param slug        URL-friendly slug, must not be {@code null} or blank
     * @param name        project name, must not be {@code null} or blank
     * @param description optional description (may be {@code null} or empty {@link Optional})
     * @param archived    whether the project is archived
     * @param createdAt   creation timestamp, must not be {@code null}
     * @param updatedAt   last-update timestamp (may be {@code null} or empty {@link Optional})
     */
    public ProjectInfo(
            String id,
            String slug,
            String name,
            Optional<String> description,
            boolean archived,
            Instant createdAt,
            Optional<Instant> updatedAt
    ) {
        Objects.requireNonNull(id, "id must not be null");
        if (id.isBlank()) {
            throw new IllegalArgumentException("id must not be blank");
        }
        Objects.requireNonNull(slug, "slug must not be null");
        if (slug.isBlank()) {
            throw new IllegalArgumentException("slug must not be blank");
        }
        Objects.requireNonNull(name, "name must not be null");
        if (name.isBlank()) {
            throw new IllegalArgumentException("name must not be blank");
        }
        Objects.requireNonNull(createdAt, "createdAt must not be null");

        this.id = id;
        this.slug = slug;
        this.name = name;
        this.description = description == null ? Optional.empty() : description;
        this.archived = archived;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt == null ? Optional.empty() : updatedAt;
    }
}
