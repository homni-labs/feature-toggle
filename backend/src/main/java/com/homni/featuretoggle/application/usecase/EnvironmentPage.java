/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.domain.model.Environment;

import java.util.List;
import java.util.Objects;

/**
 * Paginated environments.
 *
 * @param items         environments on this page
 * @param totalElements total count
 */
public record EnvironmentPage(List<Environment> items, long totalElements) {

    /** Defensive copy of items. */
    public EnvironmentPage {
        Objects.requireNonNull(items, "items must not be null");
        items = List.copyOf(items);
    }
}
