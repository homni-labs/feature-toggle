/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.model;

import java.util.Objects;
import java.util.UUID;

/**
 * Identity of an application user.
 */
public final class UserId {

    public final UUID value;

    /**
     * Wraps an existing UUID.
     *
     * @param value the UUID
     */
    public UserId(UUID value) {
        this.value = Objects.requireNonNull(value, "UserId must not be null");
    }

    /** Generates a new random identity. */
    public UserId() {
        this(UUID.randomUUID());
    }

    @Override
    public boolean equals(Object o) {
        return this == o || (o instanceof UserId that && value.equals(that.value));
    }

    @Override
    public int hashCode() {
        return value.hashCode();
    }
}
