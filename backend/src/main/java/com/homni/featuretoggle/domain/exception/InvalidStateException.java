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
 * Thrown when an operation is invalid for the current state of an entity
 * (e.g. enabling an already enabled toggle, disabling an already disabled user).
 */
public final class InvalidStateException extends DomainConflictException {

    /**
     * Creates exception for an invalid state transition.
     *
     * @param message description with entity identity
     */
    public InvalidStateException(String message) {
        super(message);
    }
}
