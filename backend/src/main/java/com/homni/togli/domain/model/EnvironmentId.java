/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import java.util.Objects;
import java.util.UUID;

/**
 * Identity of a deployment environment.
 */
public final class EnvironmentId {

    public final UUID value;

    /**
     * Wraps an existing UUID.
     *
     * @param value the UUID
     */
    public EnvironmentId(UUID value) {
        this.value = Objects.requireNonNull(value, "EnvironmentId must not be null");
    }

    /** Generates a new random identity. */
    public EnvironmentId() {
        this(UUID.randomUUID());
    }

    @Override
    public boolean equals(Object o) {
        return this == o || (o instanceof EnvironmentId that && value.equals(that.value));
    }

    @Override
    public int hashCode() {
        return value.hashCode();
    }
}
