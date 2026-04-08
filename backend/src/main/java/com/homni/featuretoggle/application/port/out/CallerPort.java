/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.port.out;

import com.homni.featuretoggle.domain.model.AppUser;

/**
 * Provides the authenticated platform user.
 */
public interface CallerPort {

    /**
     * Returns the authenticated user.
     *
     * @return the current platform user
     */
    AppUser get();
}
