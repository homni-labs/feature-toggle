/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.model;

import com.homni.featuretoggle.domain.exception.InvalidStateException;
import com.homni.featuretoggle.domain.exception.NotProjectMemberException;

import java.time.Instant;
import java.util.Objects;
import java.util.Optional;

/**
 * Platform user with OIDC authentication and platform-level role.
 */
public final class AppUser {

    public final UserId id;
    public final Email email;
    public final Instant createdAt;

    private String oidcSubject;
    private String name;
    private PlatformRole platformRole;
    private boolean active;
    private Instant updatedAt;

    /**
     * Creates a new active user with OIDC subject (USER role).
     *
     * @param oidcSubject the OIDC subject identifier
     * @param email       the email address
     * @param name        optional display name
     * @throws com.homni.featuretoggle.domain.exception.DomainValidationException if email is invalid
     */
    public AppUser(String oidcSubject, String email, String name) {
        Objects.requireNonNull(oidcSubject, "oidcSubject must not be null");
        this.id = new UserId();
        this.oidcSubject = oidcSubject;
        this.email = new Email(email);
        this.name = name;
        this.platformRole = PlatformRole.USER;
        this.active = true;
        this.createdAt = Instant.now();
        this.updatedAt = null;
    }

    /**
     * Creates a pre-provisioned user without OIDC subject.
     *
     * @param email        the email address
     * @param name         optional display name
     * @param platformRole the platform role
     * @throws com.homni.featuretoggle.domain.exception.DomainValidationException if email is invalid
     */
    public AppUser(String email, String name, PlatformRole platformRole) {
        this.id = new UserId();
        this.oidcSubject = null;
        this.email = new Email(email);
        this.name = name;
        this.platformRole = Objects.requireNonNull(platformRole);
        this.active = true;
        this.createdAt = Instant.now();
        this.updatedAt = null;
    }

    /**
     * Reconstitutes from storage.
     *
     * @param id           the user identity
     * @param oidcSubject  OIDC subject, or {@code null}
     * @param email        the validated email
     * @param name         optional display name
     * @param platformRole the platform role
     * @param active       active flag
     * @param createdAt    creation timestamp
     * @param updatedAt    last modification timestamp
     */
    public AppUser(UserId id, String oidcSubject, Email email, String name,
                   PlatformRole platformRole, boolean active,
                   Instant createdAt, Instant updatedAt) {
        this.id = Objects.requireNonNull(id);
        this.oidcSubject = oidcSubject;
        this.email = Objects.requireNonNull(email);
        this.name = name;
        this.platformRole = Objects.requireNonNull(platformRole);
        this.active = active;
        this.createdAt = Objects.requireNonNull(createdAt);
        this.updatedAt = updatedAt;
    }

    /**
     * Resolves access level for a project.
     *
     * @param projectId  the target project
     * @param membership the membership, if any
     * @return the resolved access level
     * @throws NotProjectMemberException if USER has no membership
     */
    public ProjectAccess accessFor(ProjectId projectId,
                                   Optional<ProjectMembership> membership) {
        if (this.platformRole == PlatformRole.PLATFORM_ADMIN) {
            return new PlatformAdminAccess();
        }
        ProjectMembership m = membership
                .orElseThrow(() -> new NotProjectMemberException(projectId, this.id));
        return new RoleBasedAccess(projectId, m.currentRole());
    }

    /**
     * Promotes to PLATFORM_ADMIN.
     *
     * @throws InvalidStateException if already admin
     */
    public void promoteToPlatformAdmin() {
        if (this.platformRole == PlatformRole.PLATFORM_ADMIN) {
            throw new InvalidStateException("User [id=%s, email=%s] is already a platform admin".formatted(this.id.value, this.email.value()));
        }
        this.platformRole = PlatformRole.PLATFORM_ADMIN;
        this.updatedAt = Instant.now();
    }

    /**
     * Demotes to USER.
     *
     * @throws InvalidStateException if already a regular user
     */
    public void demoteToUser() {
        if (this.platformRole == PlatformRole.USER) {
            throw new InvalidStateException("User [id=%s, email=%s] is not a platform admin".formatted(this.id.value, this.email.value()));
        }
        this.platformRole = PlatformRole.USER;
        this.updatedAt = Instant.now();
    }

    /**
     * Disables this user.
     *
     * @throws InvalidStateException if already disabled
     */
    public void disable() {
        if (!this.active) {
            throw new InvalidStateException("User [id=%s, email=%s] is already disabled".formatted(this.id.value, this.email.value()));
        }
        this.active = false;
        this.updatedAt = Instant.now();
    }

    /**
     * Activates this user.
     *
     * @throws InvalidStateException if already active
     */
    public void activate() {
        if (this.active) {
            throw new InvalidStateException("User [id=%s, email=%s] is already active".formatted(this.id.value, this.email.value()));
        }
        this.active = true;
        this.updatedAt = Instant.now();
    }

    /**
     * Binds an OIDC subject to this user.
     *
     * @param oidcSubject the OIDC subject
     * @throws InvalidStateException if already bound
     */
    public void bindOidcSubject(String oidcSubject) {
        if (this.oidcSubject != null) {
            throw new InvalidStateException("User [id=%s, email=%s] already has an OIDC subject bound".formatted(this.id.value, this.email.value()));
        }
        this.oidcSubject = Objects.requireNonNull(oidcSubject);
        this.updatedAt = Instant.now();
    }

    /**
     * Whether this user is a platform admin.
     *
     * @return {@code true} if platform admin
     */
    public boolean isPlatformAdmin() {
        return this.platformRole == PlatformRole.PLATFORM_ADMIN;
    }

    /**
     * Whether this user can authenticate.
     *
     * @return {@code true} if active
     */
    public boolean canAuthenticate() {
        return this.active;
    }

    /**
     * Whether an OIDC subject can be bound.
     *
     * @return {@code true} if no subject bound
     */
    public boolean canBindOidc() {
        return this.oidcSubject == null;
    }

    /**
     * Current platform role.
     *
     * @return the platform role
     */
    public PlatformRole platformRole() {
        return this.platformRole;
    }

    /**
     * OIDC subject identifier.
     *
     * @return the subject, or empty
     */
    public Optional<String> oidcSubject() {
        return Optional.ofNullable(this.oidcSubject);
    }

    /**
     * User's display name.
     *
     * @return the name, or empty
     */
    public Optional<String> displayName() {
        return Optional.ofNullable(this.name);
    }

    /**
     * Whether this user is active.
     *
     * @return {@code true} if active
     */
    public boolean isActive() {
        return this.active;
    }

    /**
     * Last modification timestamp.
     *
     * @return the timestamp, or empty if never modified
     */
    public Optional<Instant> lastModifiedAt() {
        return Optional.ofNullable(this.updatedAt);
    }
}
