/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.exception;

import java.util.Objects;

/**
 * Thrown when the server responds with HTTP 403 Forbidden.
 *
 * <p>The authenticated principal does not have sufficient permissions
 * to perform the requested operation.
 */
public final class TogliAccessDeniedException extends TogliException {

    /**
     * Creates a new access-denied exception.
     *
     * @param message human-readable description of the denial reason, must not be {@code null}
     */
    public TogliAccessDeniedException(String message) {
        super("FORBIDDEN", Objects.requireNonNull(message, "message must not be null"));
    }
}
