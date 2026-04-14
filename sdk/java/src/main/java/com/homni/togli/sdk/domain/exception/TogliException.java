/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.exception;

import java.util.Objects;

/**
 * Abstract base exception for all Togli SDK errors.
 *
 * <p>Every Togli error carries a machine-readable {@link #errorCode} and a
 * human-readable {@link #errorMessage}. The standard {@link #getMessage()}
 * method returns them combined as {@code "errorCode: errorMessage"}.
 */
public abstract class TogliException extends RuntimeException {

    /** Machine-readable error code (e.g. {@code "UNAUTHORIZED"}, {@code "NETWORK_ERROR"}). */
    public final String errorCode;

    /** Human-readable description of the error. */
    public final String errorMessage;

    /**
     * Creates a new Togli exception.
     *
     * @param errorCode    machine-readable error code, must not be {@code null}
     * @param errorMessage human-readable error description, must not be {@code null}
     */
    protected TogliException(String errorCode, String errorMessage) {
        super(errorCode + ": " + errorMessage);
        this.errorCode = Objects.requireNonNull(errorCode, "errorCode must not be null");
        this.errorMessage = Objects.requireNonNull(errorMessage, "errorMessage must not be null");
    }

    /**
     * Creates a new Togli exception with an underlying cause.
     *
     * @param errorCode    machine-readable error code, must not be {@code null}
     * @param errorMessage human-readable error description, must not be {@code null}
     * @param cause        the underlying cause
     */
    protected TogliException(String errorCode, String errorMessage, Throwable cause) {
        super(errorCode + ": " + errorMessage, cause);
        this.errorCode = Objects.requireNonNull(errorCode, "errorCode must not be null");
        this.errorMessage = Objects.requireNonNull(errorMessage, "errorMessage must not be null");
    }
}
