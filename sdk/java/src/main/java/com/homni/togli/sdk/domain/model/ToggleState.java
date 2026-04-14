/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

import java.util.Objects;

/**
 * The state of a feature toggle in a specific environment.
 *
 * @param environmentName the name of the environment (e.g. {@code "production"}), must not be {@code null} or blank
 * @param enabled         whether the toggle is enabled in this environment
 */
public record ToggleState(String environmentName, boolean enabled) {

    /**
     * Creates a new toggle state after validating invariants.
     */
    public ToggleState {
        Objects.requireNonNull(environmentName, "environmentName must not be null");
        if (environmentName.isBlank()) {
            throw new IllegalArgumentException("environmentName must not be blank");
        }
    }
}
