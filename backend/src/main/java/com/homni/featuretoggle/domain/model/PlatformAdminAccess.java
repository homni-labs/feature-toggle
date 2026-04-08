/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.model;

/**
 * Unrestricted access for platform administrators.
 */
public final class PlatformAdminAccess implements ProjectAccess {

    /**
     * No-op: platform admins have all permissions.
     *
     * @param permission ignored
     */
    @Override
    public void ensure(Permission permission) {
        // Platform admin has all permissions — nothing to check.
    }
}
