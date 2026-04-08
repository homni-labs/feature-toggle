/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.domain.model.FeatureToggle;

import java.util.List;
import java.util.Objects;

/**
 * Paginated feature toggles.
 *
 * @param items         toggles on this page
 * @param totalElements total count
 */
public record TogglePage(List<FeatureToggle> items, long totalElements) {

    /** Defensive copy of items. */
    public TogglePage {
        Objects.requireNonNull(items, "items must not be null");
        items = List.copyOf(items);
    }
}
