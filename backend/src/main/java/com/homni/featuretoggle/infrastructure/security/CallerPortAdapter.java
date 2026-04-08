/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.security;

import com.homni.featuretoggle.application.port.out.CallerPort;
import com.homni.featuretoggle.domain.model.AppUser;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
 * Extracts the currently authenticated platform user from the Spring Security context.
 */
@Component
public class CallerPortAdapter implements CallerPort {

    /**
     * {@inheritDoc}
     */
    @Override
    public AppUser get() {
        return ((AppUserAuthentication) SecurityContextHolder.getContext().getAuthentication()).user;
    }
}
