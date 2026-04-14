/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.cache;

import com.homni.togli.sdk.application.port.out.TogliApiPort;
import com.homni.togli.sdk.infrastructure.config.TogliConfiguration;

import java.util.Objects;

/**
 * Factory for creating {@link ToggleCache} instances based on the SDK configuration.
 *
 * <p>This factory encapsulates the decision between a polling cache and a no-op cache,
 * keeping the concrete cache implementations package-private.
 */
public final class CacheFactory {

    private CacheFactory() {
        throw new AssertionError("No instances");
    }

    /**
     * Creates and starts the appropriate cache based on the configuration.
     *
     * <p>If caching is enabled, a {@link PollingToggleCache} is created and started
     * (performing an initial synchronous fetch). Otherwise, a {@link NoOpToggleCache}
     * is returned.
     *
     * @param api       the API port used by the polling cache, must not be {@code null}
     * @param projectId the project identifier to cache toggles for, must not be {@code null}
     * @param config    the SDK configuration, must not be {@code null}
     * @return a started cache instance, never {@code null}
     */
    public static ToggleCache create(TogliApiPort api, String projectId, TogliConfiguration config) {
        Objects.requireNonNull(api, "api must not be null");
        Objects.requireNonNull(projectId, "projectId must not be null");
        Objects.requireNonNull(config, "config must not be null");

        if (config.cacheEnabled) {
            PollingToggleCache cache = new PollingToggleCache(api, projectId, config.pollingInterval);
            cache.start();
            return cache;
        }
        return new NoOpToggleCache();
    }
}
