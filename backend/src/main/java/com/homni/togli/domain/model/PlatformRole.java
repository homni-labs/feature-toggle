/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

/**
 * Platform-wide user roles.
 */
public enum PlatformRole {

    /** Unrestricted access to all projects. */
    PLATFORM_ADMIN,

    /** Access governed by per-project roles. */
    USER
}
