/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.exception;

/**
 * Thrown when an operation conflicts with existing domain state.
 */
public abstract class DomainConflictException extends DomainException {

    /**
     * Creates a conflict exception.
     *
     * @param message conflict description
     */
    protected DomainConflictException(String message) {
        super(message);
    }
}
