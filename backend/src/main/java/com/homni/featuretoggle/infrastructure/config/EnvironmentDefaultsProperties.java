/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

/**
 * Platform-wide list of "default" environment names that can be bootstrapped
 * into a new project at creation time. Lives in {@code application.yml} under
 * {@code app.environments.defaults} (overridable via the
 * {@code APP_DEFAULT_ENVIRONMENTS} environment variable). The list is the
 * single source of truth — names are never duplicated in the database; each
 * project that selects them gets its own independent rows in the
 * {@code environment} table.
 */
@ConfigurationProperties(prefix = "app.environments")
public record EnvironmentDefaultsProperties(List<String> defaults) {

    /**
     * Returns the configured defaults as an immutable list, or an empty list
     * if none are configured.
     *
     * @return the defaults, never {@code null}
     */
    public List<String> defaultsOrEmpty() {
        return defaults != null ? List.copyOf(defaults) : List.of();
    }
}
