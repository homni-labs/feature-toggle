/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.exception;

import java.util.Objects;

/**
 * Thrown when the server responds with an unexpected HTTP status (typically 4xx or 5xx).
 *
 * <p>Carries the raw {@link #httpStatus} code in addition to the standard
 * {@link #errorCode} and {@link #errorMessage}.
 */
public final class TogliServerException extends TogliException {

    /** The HTTP status code returned by the server. */
    public final int httpStatus;

    /**
     * Creates a new server exception.
     *
     * @param httpStatus   the HTTP status code returned by the server
     * @param errorCode    machine-readable error code, must not be {@code null}
     * @param errorMessage human-readable error description, must not be {@code null}
     */
    public TogliServerException(int httpStatus, String errorCode, String errorMessage) {
        super(
                Objects.requireNonNull(errorCode, "errorCode must not be null"),
                Objects.requireNonNull(errorMessage, "errorMessage must not be null")
        );
        this.httpStatus = httpStatus;
    }
}
