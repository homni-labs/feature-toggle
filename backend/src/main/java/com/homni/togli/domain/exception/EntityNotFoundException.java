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
 * Thrown when an entity is not found by its identifier.
 */
public final class EntityNotFoundException extends DomainNotFoundException {

    /**
     * Creates exception for a missing entity.
     *
     * @param entity the entity type name
     * @param id     the identifier value
     */
    public EntityNotFoundException(String entity, Object id) {
        super("%s [id=%s] not found".formatted(entity, id));
    }
}
