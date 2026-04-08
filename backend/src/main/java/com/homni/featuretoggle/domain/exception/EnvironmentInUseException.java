/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.exception;

/**
 * Thrown when attempting to delete an environment that is still referenced by feature toggles.
 */
public final class EnvironmentInUseException extends DomainConflictException {

    /**
     * Creates exception for an environment still referenced by toggles.
     *
     * @param name the environment name in use
     */
    public EnvironmentInUseException(String name) {
        super("Environment '%s' is still used by one or more feature toggles".formatted(name));
    }
}
