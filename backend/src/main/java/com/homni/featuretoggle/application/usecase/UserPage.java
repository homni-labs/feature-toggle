/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.domain.model.AppUser;

import java.util.List;
import java.util.Objects;

/**
 * Paginated users.
 *
 * @param items         users on this page
 * @param totalElements total count
 */
public record UserPage(List<AppUser> items, long totalElements) {

    /** Defensive copy of items. */
    public UserPage {
        Objects.requireNonNull(items, "items must not be null");
        items = List.copyOf(items);
    }
}
