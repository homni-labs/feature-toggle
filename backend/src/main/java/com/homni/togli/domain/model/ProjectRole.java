/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import static com.homni.togli.domain.model.Permission.MANAGE_MEMBERS;
import static com.homni.togli.domain.model.Permission.READ_TOGGLES;
import static com.homni.togli.domain.model.Permission.WRITE_TOGGLES;

import java.util.Set;

/**
 * Role within a project, defining permitted operations.
 */
public enum ProjectRole {

    /** Full control: read, write, manage members. */
    ADMIN(Set.of(READ_TOGGLES, WRITE_TOGGLES, MANAGE_MEMBERS)),

    /** Read and write toggles, no member management. */
    EDITOR(Set.of(READ_TOGGLES, WRITE_TOGGLES)),

    /** Read-only access. */
    READER(Set.of(READ_TOGGLES));

    private final Set<Permission> permissions;

    ProjectRole(Set<Permission> permissions) {
        this.permissions = Set.copyOf(permissions);
    }

    /**
     * Whether this role includes the given permission.
     *
     * @param permission the permission to check
     * @return {@code true} if granted
     */
    public boolean has(Permission permission) {
        return this.permissions.contains(permission);
    }
}
