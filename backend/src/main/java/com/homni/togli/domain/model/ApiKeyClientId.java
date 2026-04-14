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
 * Identity of an API key client.
 */
public record ApiKeyClientId(UUID value) {

    public ApiKeyClientId {
        Objects.requireNonNull(value, "ApiKeyClientId must not be null");
    }

    /** Generates a new random identity. */
    public ApiKeyClientId() {
        this(UUID.randomUUID());
    }
}
