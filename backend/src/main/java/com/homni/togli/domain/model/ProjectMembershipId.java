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
 * Identity of a project membership record.
 */
public final class ProjectMembershipId {

    public final UUID value;

    /**
     * Wraps an existing UUID.
     *
     * @param value the UUID
     */
    public ProjectMembershipId(UUID value) {
        this.value = Objects.requireNonNull(value, "ProjectMembershipId must not be null");
    }

    /** Generates a new random identity. */
    public ProjectMembershipId() {
        this(UUID.randomUUID());
    }

    @Override
    public boolean equals(Object o) {
        return this == o || (o instanceof ProjectMembershipId that && value.equals(that.value));
    }

    @Override
    public int hashCode() {
        return value.hashCode();
    }
}
