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

/**
 * API key scoped to a project with a specific project role.
 */
public final class ApiKey {

    private static final String TOKEN_PREFIX = "hft_";

    public final ApiKeyId id;
    public final ProjectId projectId;
    public final ProjectRole projectRole;
    public final String name;
    public final Instant createdAt;
    public final TokenHash tokenHash;
    public final Instant expiresAt;

    private boolean active;

    /**
     * Creates a new active API key for a project.
     *
     * @param projectId   the owning project
     * @param name        key name (1-255 chars)
     * @param projectRole the granted role
     * @param tokenHash   SHA-256 hash of the token
     * @param expiresAt   expiration, or {@code null}
     * @throws DomainValidationException if name is invalid
     */
    public ApiKey(ProjectId projectId, String name, ProjectRole projectRole,
                  TokenHash tokenHash, Instant expiresAt) {
        this.id = new ApiKeyId();
        this.projectId = Objects.requireNonNull(projectId);
        this.projectRole = Objects.requireNonNull(projectRole);
        this.name = validateName(name);
        this.tokenHash = Objects.requireNonNull(tokenHash);
        this.active = true;
        this.createdAt = Instant.now();
        this.expiresAt = expiresAt;
    }

    /**
     * Reconstitutes from storage.
     *
     * @param id          the API key identity
     * @param projectId   the owning project
     * @param name        the key name
     * @param projectRole the granted role
     * @param tokenHash   SHA-256 hash of the token
     * @param active      active flag
     * @param createdAt   creation timestamp
     * @param expiresAt   expiration, or {@code null}
     * @throws DomainValidationException if name is invalid
     */
    public ApiKey(ApiKeyId id, ProjectId projectId, String name, ProjectRole projectRole,
                  TokenHash tokenHash, boolean active, Instant createdAt, Instant expiresAt) {
        this.id = Objects.requireNonNull(id);
        this.projectId = Objects.requireNonNull(projectId);
        this.projectRole = Objects.requireNonNull(projectRole);
        this.name = validateName(name);
        this.tokenHash = Objects.requireNonNull(tokenHash);
        this.active = active;
        this.createdAt = Objects.requireNonNull(createdAt);
        this.expiresAt = expiresAt;
    }

    /**
     * Revokes this API key.
     *
     * @throws InvalidStateException if already revoked
     */
    public void revoke() {
        if (!this.active) {
            throw new InvalidStateException("API key [id=%s, name=%s] is already revoked".formatted(this.id.value, this.name));
        }
        this.active = false;
    }

    /**
     * Whether the key is active and not expired.
     *
     * @return {@code true} if valid
     */
    public boolean isValid() {
        return active && (expiresAt == null || Instant.now().isBefore(expiresAt));
    }

    /**
     * Whether this key is active (not revoked).
     *
     * @return {@code true} if active
     */
    public boolean isActive() {
        return this.active;
    }

    /**
     * Masked token representation for safe display.
     *
     * @return the masked token string
     */
    public String maskedToken() {
        String hash = tokenHash.value;
        String suffix = hash.substring(Math.max(0, hash.length() - 4));
        return TOKEN_PREFIX + "****" + suffix;
    }

    private String validateName(String name) {
        if (name == null || name.isBlank() || name.length() > 255) {
            throw new DomainValidationException("Invalid API key name: " + name);
        }
        return name;
    }
}
