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
 * Thrown when attempting to create an entity that already exists (uniqueness violation).
 */
public final class AlreadyExistsException extends DomainConflictException {

    /**
     * Creates exception for a uniqueness violation.
     *
     * @param entity     the entity type name
     * @param identifier the conflicting identifier
     */
    public AlreadyExistsException(String entity, String identifier) {
        super("%s '%s' already exists".formatted(entity, identifier));
    }
}
