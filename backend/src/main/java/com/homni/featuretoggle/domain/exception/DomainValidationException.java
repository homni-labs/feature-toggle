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
 * Thrown when a domain invariant is violated during object creation or mutation.
 */
public class DomainValidationException extends DomainException {

    /**
     * Creates a validation exception.
     *
     * @param message validation failure description
     */
    public DomainValidationException(String message) {
        super(message);
    }
}
