/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.InsufficientPermissionException;

import java.util.Objects;

/**
 * Access governed by a {@link ProjectRole} within a project.
 */
public final class RoleBasedAccess implements ProjectAccess {

    public final ProjectId projectId;
    private final ProjectRole role;

    /**
     * Creates role-based access for a project.
     *
     * @param projectId the project identity
     * @param role      the assigned role
     */
    public RoleBasedAccess(ProjectId projectId, ProjectRole role) {
        this.projectId = Objects.requireNonNull(projectId, "ProjectId must not be null");
        this.role = Objects.requireNonNull(role, "ProjectRole must not be null");
    }

    /**
     * Verifies the role grants the required permission.
     *
     * @param permission the required permission
     * @throws InsufficientPermissionException if not granted
     */
    @Override
    public void ensure(Permission permission) {
        if (!this.role.has(permission)) {
            throw new InsufficientPermissionException(this.projectId, permission);
        }
    }
}
