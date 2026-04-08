/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.CallerPort;
import com.homni.featuretoggle.domain.model.AppUser;

/**
 * Returns the authenticated platform user.
 */
public final class GetCurrentUserUseCase {

    private final CallerPort callerPort;

    /**
     * @param callerPort authenticated caller provider
     */
    public GetCurrentUserUseCase(CallerPort callerPort) {
        this.callerPort = callerPort;
    }

    /**
     * Returns the authenticated user.
     *
     * @return the current platform user
     */
    public AppUser execute() {
        return callerPort.get();
    }
}
