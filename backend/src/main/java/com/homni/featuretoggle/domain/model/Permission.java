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
 * Permissions governing project resource access.
 */
public enum Permission {

    /** Read toggle states. */
    READ_TOGGLES,

    /** Create, update, enable, disable toggles. */
    WRITE_TOGGLES,

    /** Add, remove, change roles of members. */
    MANAGE_MEMBERS
}
