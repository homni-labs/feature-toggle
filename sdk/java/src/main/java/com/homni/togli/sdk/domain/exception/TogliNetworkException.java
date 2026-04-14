/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.exception;

import java.util.Objects;

/**
 * Thrown when a network-level error prevents communication with the Togli server.
 *
 * <p>Wraps I/O and connection errors such as timeouts, DNS failures, and
 * refused connections.
 */
public final class TogliNetworkException extends TogliException {

    /**
     * Creates a new network exception.
     *
     * @param message human-readable description of the network error, must not be {@code null}
     * @param cause   the underlying I/O exception
     */
    public TogliNetworkException(String message, Throwable cause) {
        super("NETWORK_ERROR", Objects.requireNonNull(message, "message must not be null"), cause);
    }
}
