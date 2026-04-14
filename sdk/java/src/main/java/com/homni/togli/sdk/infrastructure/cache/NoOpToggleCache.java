/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.cache;

import com.homni.togli.sdk.domain.model.Toggle;

import java.util.List;
import java.util.Optional;

/**
 * A no-op cache that always returns empty results.
 *
 * <p>Used when caching is explicitly disabled by the user. All read operations
 * return empty collections; all write and lifecycle operations are no-ops.
 */
final class NoOpToggleCache implements ToggleCache {

    /**
     * Creates a new no-op cache instance.
     */
    NoOpToggleCache() {
    }

    /**
     * Always returns {@link Optional#empty()}.
     *
     * @param name the toggle name (ignored)
     * @return {@link Optional#empty()}
     */
    @Override
    public Optional<Toggle> findByName(String name) {
        return Optional.empty();
    }

    /**
     * Always returns an empty list.
     *
     * @return an empty unmodifiable list
     */
    @Override
    public List<Toggle> all() {
        return List.of();
    }

    /**
     * No-op; the cache is disabled.
     *
     * @param toggles ignored
     */
    @Override
    public void refresh(List<Toggle> toggles) {
        // no-op
    }

    /**
     * No-op; the cache is disabled.
     */
    @Override
    public void start() {
        // no-op
    }

    /**
     * No-op; the cache is disabled.
     */
    @Override
    public void stop() {
        // no-op
    }
}
