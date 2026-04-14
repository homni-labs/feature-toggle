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

/**
 * User's access level within a project.
 */
public sealed interface ProjectAccess permits PlatformAdminAccess, RoleBasedAccess {

    /**
     * Verifies the required permission is granted.
     *
     * @param permission the required permission
     * @throws InsufficientPermissionException if not granted
     */
    void ensure(Permission permission);
}
