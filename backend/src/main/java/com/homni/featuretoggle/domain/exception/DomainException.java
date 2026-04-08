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
 * Base class for all domain exceptions.
 */
public abstract class DomainException extends RuntimeException {

    /**
     * Creates a domain exception.
     *
     * @param message error description
     */
    protected DomainException(String message) {
        super(message);
    }
}
