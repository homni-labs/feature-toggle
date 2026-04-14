/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

import java.util.List;
import java.util.Objects;

/**
 * A paged result of {@link EnvironmentInfo} instances.
 *
 * @param items      the environments on this page (unmodifiable), must not be {@code null}
 * @param pagination pagination metadata, must not be {@code null}
 */
public record EnvironmentPage(List<EnvironmentInfo> items, Pagination pagination) {

    /**
     * Creates a new environment page after validating invariants and taking a defensive copy of items.
     */
    public EnvironmentPage {
        Objects.requireNonNull(items, "items must not be null");
        Objects.requireNonNull(pagination, "pagination must not be null");
        items = List.copyOf(items);
    }
}
