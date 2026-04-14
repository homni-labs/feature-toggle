/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.DomainValidationException;

/**
 * Email address value object with format validation.
 *
 * @param value the normalized email address
 */
public record Email(String value) {

    /**
     * Validates and normalizes to lowercase.
     *
     * @param value the raw email string
     * @throws DomainValidationException if format is invalid
     */
    public Email {
        if (value == null || value.isBlank()
                || !value.matches("^[\\w.+-]+@[\\w.-]+\\.[a-zA-Z]{2,}$")) {
            throw new DomainValidationException("Invalid email: " + value);
        }
        value = value.toLowerCase().trim();
    }
}
