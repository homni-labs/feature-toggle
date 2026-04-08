/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.Optional;

/**
 * User's membership and role within a project.
 */
public final class ProjectMembership {

    public final ProjectMembershipId id;
    public final ProjectId projectId;
    public final UserId userId;
    public final Instant grantedAt;

    private ProjectRole role;
    private Instant updatedAt;
    private String email;
    private String displayName;

    /**
     * Creates a new project membership.
     *
     * @param projectId the project identity
     * @param userId    the user identity
     * @param role      the initial role
     */
    public ProjectMembership(ProjectId projectId, UserId userId, ProjectRole role) {
        this.id = new ProjectMembershipId();
        this.projectId = Objects.requireNonNull(projectId, "ProjectId must not be null");
        this.userId = Objects.requireNonNull(userId, "UserId must not be null");
        this.role = Objects.requireNonNull(role, "ProjectRole must not be null");
        this.grantedAt = Instant.now();
        this.updatedAt = null;
    }

    /**
     * Reconstitutes from storage.
     *
     * @param id        the membership identity
     * @param projectId the project identity
     * @param userId    the user identity
     * @param role      the assigned role
     * @param grantedAt grant timestamp
     * @param updatedAt last modification timestamp
     */
    public ProjectMembership(ProjectMembershipId id, ProjectId projectId, UserId userId,
                             ProjectRole role, Instant grantedAt, Instant updatedAt) {
        this.id = Objects.requireNonNull(id, "ProjectMembershipId must not be null");
        this.projectId = Objects.requireNonNull(projectId, "ProjectId must not be null");
        this.userId = Objects.requireNonNull(userId, "UserId must not be null");
        this.role = Objects.requireNonNull(role, "ProjectRole must not be null");
        this.grantedAt = Objects.requireNonNull(grantedAt, "grantedAt must not be null");
        this.updatedAt = updatedAt;
    }

    /**
     * Reconstitutes from storage with user info (JOIN query).
     *
     * @param id          the membership identity
     * @param projectId   the project identity
     * @param userId      the user identity
     * @param role        the assigned role
     * @param grantedAt   grant timestamp
     * @param updatedAt   last modification timestamp
     * @param email       the user's email
     * @param displayName the user's display name
     */
    public ProjectMembership(ProjectMembershipId id, ProjectId projectId, UserId userId,
                             ProjectRole role, Instant grantedAt, Instant updatedAt,
                             String email, String displayName) {
        this(id, projectId, userId, role, grantedAt, updatedAt);
        this.email = email;
        this.displayName = displayName;
    }

    /**
     * Changes the role of this member.
     *
     * @param newRole the new role
     */
    public void changeRole(ProjectRole newRole) {
        Objects.requireNonNull(newRole, "ProjectRole must not be null");
        this.role = newRole;
        this.updatedAt = Instant.now();
    }

    /**
     * Current role of this member.
     *
     * @return the project role
     */
    public ProjectRole currentRole() {
        return this.role;
    }

    /**
     * Last modification timestamp.
     *
     * @return the timestamp, or empty if never modified
     */
    public Optional<Instant> lastModifiedAt() {
        return Optional.ofNullable(this.updatedAt);
    }

    /**
     * Enriches with user display info from a loaded user.
     *
     * @param email       the user's email
     * @param displayName the display name
     */
    public void enrichWithUserInfo(String email, String displayName) {
        this.email = email;
        this.displayName = displayName;
    }

    /**
     * Member's email, if loaded via JOIN.
     *
     * @return the email, or empty
     */
    public Optional<String> email() {
        return Optional.ofNullable(this.email);
    }

    /**
     * Member's display name, if loaded via JOIN.
     *
     * @return the display name, or empty
     */
    public Optional<String> displayName() {
        return Optional.ofNullable(this.displayName);
    }
}
