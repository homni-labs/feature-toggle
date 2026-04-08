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
 * Thrown when a domain operation is denied due to insufficient access rights.
 */
public class DomainAccessDeniedException extends DomainException {

    /**
     * Creates an access-denied exception.
     *
     * @param message access denial description
     */
    public DomainAccessDeniedException(String message) {
        super(message);
    }
}
