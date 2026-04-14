/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.cache;

import com.homni.togli.sdk.domain.model.Toggle;

import java.util.List;
import java.util.Optional;

/**
 * Internal cache abstraction for feature toggles.
 *
 * <p>Implementations must be thread-safe: reads may occur concurrently with
 * background refresh operations.
 */
public interface ToggleCache {

    /**
     * Finds a toggle by its name.
     *
     * @param name the toggle name to look up, must not be {@code null}
     * @return the toggle wrapped in an {@link Optional}, or {@link Optional#empty()} if not cached
     */
    Optional<Toggle> findByName(String name);

    /**
     * Returns all cached toggles.
     *
     * @return an unmodifiable list of all cached toggles, never {@code null}
     */
    List<Toggle> all();

    /**
     * Replaces the entire cache content with the given toggles.
     *
     * @param toggles the new set of toggles, must not be {@code null}
     */
    void refresh(List<Toggle> toggles);

    /**
     * Starts the cache (e.g. initial fetch and periodic polling).
     */
    void start();

    /**
     * Stops the cache and releases any background resources.
     */
    void stop();
}
