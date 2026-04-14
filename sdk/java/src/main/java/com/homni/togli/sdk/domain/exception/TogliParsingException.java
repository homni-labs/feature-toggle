/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.exception;

import java.util.Objects;

/**
 * Thrown when a server response cannot be parsed.
 *
 * <p>This typically indicates malformed or unexpected JSON in the HTTP response body.
 */
public final class TogliParsingException extends TogliException {

    /**
     * Creates a new parsing exception.
     *
     * @param message human-readable description of the parsing failure, must not be {@code null}
     */
    public TogliParsingException(String message) {
        super("PARSE_ERROR", Objects.requireNonNull(message, "message must not be null"));
    }
}
