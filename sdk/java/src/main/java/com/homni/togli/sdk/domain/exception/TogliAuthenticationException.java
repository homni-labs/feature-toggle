/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.exception;

/**
 * Thrown when the server responds with HTTP 401 Unauthorized.
 *
 * <p>This typically means the API key is invalid, expired, or has been revoked.
 */
public final class TogliAuthenticationException extends TogliException {

    /**
     * Creates a new authentication exception with a default message.
     */
    public TogliAuthenticationException() {
        super("UNAUTHORIZED", "API key is invalid, expired, or revoked");
    }
}
