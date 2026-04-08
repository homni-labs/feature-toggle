/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.domain.model.ProjectMembership;

import java.util.List;
import java.util.Objects;

/**
 * Paginated project memberships.
 *
 * @param items         memberships on this page
 * @param totalElements total count
 */
public record MemberPage(List<ProjectMembership> items, long totalElements) {

    /** Defensive copy of items. */
    public MemberPage {
        Objects.requireNonNull(items, "items must not be null");
        items = List.copyOf(items);
    }
}
