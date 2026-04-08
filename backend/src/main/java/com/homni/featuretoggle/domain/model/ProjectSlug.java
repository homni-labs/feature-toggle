/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.model;

import com.homni.featuretoggle.domain.exception.DomainValidationException;

/**
 * Unique project slug (2-50 uppercase alphanumeric, hyphens, underscores).
 *
 * @param value the normalized uppercase slug
 */
public record ProjectSlug(String value) {

    private static final String SLUG_PATTERN = "^[A-Z][A-Z0-9_-]*$";

    /**
     * Validates and normalizes to uppercase.
     *
     * @throws DomainValidationException if slug is invalid
     */
    public ProjectSlug {
        if (value == null || value.isBlank()) {
            throw new DomainValidationException("Invalid project slug '%s': must not be blank".formatted(String.valueOf(value)));
        }
        value = value.toUpperCase().trim();
        if (value.length() < 2 || value.length() > 50) {
            throw new DomainValidationException("Invalid project slug '%s': length must be between 2 and 50 characters".formatted(value));
        }
        if (!value.matches(SLUG_PATTERN)) {
            throw new DomainValidationException("Invalid project slug '%s': must start with a letter and contain only letters, digits, hyphens, and underscores".formatted(value));
        }
    }
}
