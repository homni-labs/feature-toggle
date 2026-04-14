/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.exception;

import java.util.Objects;

/**
 * Thrown when the server responds with HTTP 404 Not Found.
 *
 * <p>The requested resource could not be located. The error message includes
 * both the resource type and identifier for easier troubleshooting.
 */
public final class TogliNotFoundException extends TogliException {

    /**
     * Creates a new not-found exception.
     *
     * @param resourceType the type of the missing resource (e.g. {@code "Toggle"}), must not be {@code null}
     * @param identifier   the identifier that was looked up (e.g. {@code "dark-mode"}), must not be {@code null}
     */
    public TogliNotFoundException(String resourceType, String identifier) {
        super(
                "NOT_FOUND",
                Objects.requireNonNull(resourceType, "resourceType must not be null")
                        + " [" + Objects.requireNonNull(identifier, "identifier must not be null") + "] not found"
        );
    }
}
