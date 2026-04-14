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
 * Thrown when a requested domain entity is not found.
 */
public abstract class DomainNotFoundException extends DomainException {

    /**
     * Creates a not-found exception.
     *
     * @param message missing entity description
     */
    protected DomainNotFoundException(String message) {
        super(message);
    }
}
