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
import java.util.Objects;
import java.util.Optional;

/**
 * Aggregate root representing a project that groups feature toggles.
 */
public final class Project {

    public final ProjectId id;
    public final ProjectSlug slug;
    public final Instant createdAt;

    private String name;
    private String description;
    private boolean archived;
    private Instant updatedAt;

    /**
     * Creates a new active project.
     *
     * @param slug        the unique project slug
     * @param name        the project name (1-255 chars)
     * @param description optional description
     * @throws DomainValidationException if name is invalid
     */
    public Project(ProjectSlug slug, String name, String description) {
        this.id = new ProjectId();
        this.slug = Objects.requireNonNull(slug, "ProjectSlug must not be null");
        this.name = validateName(name);
        this.description = description;
        this.archived = false;
        this.createdAt = Instant.now();
        this.updatedAt = null;
    }

    /**
     * Reconstitutes from storage.
     *
     * @param id          the project identity
     * @param slug        the unique project slug
     * @param name        the project name
     * @param description optional description
     * @param archived    archived flag
     * @param createdAt   creation timestamp
     * @param updatedAt   last modification timestamp
     * @throws DomainValidationException if name is invalid
     */
    public Project(ProjectId id, ProjectSlug slug, String name, String description,
                   boolean archived, Instant createdAt, Instant updatedAt) {
        this.id = Objects.requireNonNull(id, "ProjectId must not be null");
        this.slug = Objects.requireNonNull(slug, "ProjectSlug must not be null");
        this.name = validateName(name);
        this.description = description;
        this.archived = archived;
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt must not be null");
        this.updatedAt = updatedAt;
    }

    /**
     * Partially updates name and/or description. {@code null} arguments are ignored.
     * No-op if nothing actually changes.
     *
     * @param newName        the new name (1-255 chars), or {@code null} to keep current
     * @param newDescription the new description, or {@code null} to keep current
     * @throws DomainValidationException if name is invalid
     */
    public void update(String newName, String newDescription) {
        boolean nameChanged = newName != null && !newName.equals(this.name);
        boolean descriptionChanged = newDescription != null && !Objects.equals(newDescription, this.description);
        if (!nameChanged && !descriptionChanged) {
            return;
        }
        if (nameChanged) {
            this.name = validateName(newName);
        }
        if (descriptionChanged) {
            this.description = newDescription;
        }
        this.updatedAt = Instant.now();
    }

    /**
     * Archives this project.
     *
     * @throws InvalidStateException if already archived
     */
    public void archive() {
        if (this.archived) {
            throw new InvalidStateException("Project [id=%s, slug=%s] is already archived".formatted(this.id.value, this.slug.value()));
        }
        this.archived = true;
        this.updatedAt = Instant.now();
    }

    /**
     * Restores this project from archived state.
     *
     * @throws InvalidStateException if not archived
     */
    public void unarchive() {
        if (!this.archived) {
            throw new InvalidStateException("Project [id=%s, slug=%s] is not archived".formatted(this.id.value, this.slug.value()));
        }
        this.archived = false;
        this.updatedAt = Instant.now();
    }

    /**
     * Current project name.
     *
     * @return the project name
     */
    public String name() {
        return this.name;
    }

    /**
     * Whether this project is archived.
     *
     * @return {@code true} if archived
     */
    public boolean isArchived() {
        return this.archived;
    }

    /**
     * Project description.
     *
     * @return the description, or empty
     */
    public Optional<String> description() {
        return Optional.ofNullable(this.description);
    }

    /**
     * Last modification timestamp.
     *
     * @return the timestamp, or empty if never modified
     */
    public Optional<Instant> lastModifiedAt() {
        return Optional.ofNullable(this.updatedAt);
    }

    private String validateName(String name) {
        if (name == null || name.isBlank() || name.length() > 255) {
            throw new DomainValidationException("Invalid project name: " + name);
        }
        return name;
    }
}
