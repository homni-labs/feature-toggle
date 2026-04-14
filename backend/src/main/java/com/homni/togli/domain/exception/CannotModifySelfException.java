/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.exception;

import com.homni.togli.domain.model.UserId;

/**
 * Thrown when a platform admin attempts to modify their own account
 * (change role, disable, etc.).
 */
public final class CannotModifySelfException extends DomainConflictException {

    /**
     * Creates exception for a self-modification attempt.
     *
     * @param id the user identity
     */
    public CannotModifySelfException(UserId id) {
        super("Cannot modify own account [id=%s]".formatted(id.value));
    }
}
