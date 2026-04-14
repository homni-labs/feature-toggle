/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.config;

import com.homni.togli.sdk.TogliClient;
import com.homni.togli.sdk.domain.exception.TogliException;

import java.time.Duration;
import java.util.Objects;
import java.util.function.Consumer;

/**
 * Immutable configuration for the Togli SDK.
 *
 * <p>Required fields ({@link #baseUrl}, {@link #apiKey}, {@link #projectSlug})
 * must not be {@code null} or blank. When {@link #cacheEnabled} is {@code true},
 * {@link #pollingInterval} must be at least 5 seconds.
 */
public final class TogliConfiguration {

    /** Base URL of the Togli API. */
    public final String baseUrl;

    /** API key used for authentication. */
    public final String apiKey;

    /** Slug of the project to load toggles for. */
    public final String projectSlug;

    /** Interval between background polling cycles (default 60 minutes). */
    public final Duration pollingInterval;

    /** HTTP request timeout (default 10 seconds). */
    public final Duration requestTimeout;

    /** TCP connect timeout (default 5 seconds). */
    public final Duration connectTimeout;

    /** Whether the local cache is enabled (default {@code true}). */
    public final boolean cacheEnabled;

    /** Whether to eagerly load toggles on initialization (default {@code true}). */
    public final boolean eagerInit;

    /** Callback invoked when {@code isEnabled()} swallows an error. May be {@code null}. */
    public final Consumer<TogliException> errorListener;

    /** Default environment used by {@code isEnabled(toggleName)}. May be {@code null}. */
    public final String defaultEnvironment;

    /** Callback invoked after successful initialization. May be {@code null}. */
    public final Consumer<TogliClient> readyListener;

    /** Service name sent in X-Togli-Service header. Required. */
    public final String serviceName;

    /** Kubernetes namespace sent in X-Togli-Namespace header. May be {@code null}. */
    public final String namespace;

    private static final Duration DEFAULT_POLLING_INTERVAL = Duration.ofMinutes(60);
    private static final Duration DEFAULT_REQUEST_TIMEOUT = Duration.ofSeconds(10);
    private static final Duration DEFAULT_CONNECT_TIMEOUT = Duration.ofSeconds(5);
    private static final Duration MIN_POLLING_INTERVAL = Duration.ofSeconds(5);

    /**
     * Creates a new configuration with all defaults.
     *
     * @param baseUrl     API base URL, must not be {@code null} or blank
     * @param apiKey      API key, must not be {@code null} or blank
     * @param projectSlug project slug, must not be {@code null} or blank
     */
    public TogliConfiguration(String baseUrl, String apiKey, String projectSlug, String serviceName) {
        this(baseUrl, apiKey, projectSlug, null, null, null, true, true, null, null, null, serviceName, null);
    }

    /**
     * Creates a new configuration with full control over all parameters.
     *
     * @param baseUrl         API base URL, must not be {@code null} or blank
     * @param apiKey          API key, must not be {@code null} or blank
     * @param projectSlug     project slug, must not be {@code null} or blank
     * @param pollingInterval interval between polling cycles, or {@code null} for default (60 min)
     * @param requestTimeout  HTTP request timeout, or {@code null} for default (10s)
     * @param connectTimeout  TCP connect timeout, or {@code null} for default (5s)
     * @param cacheEnabled    whether to enable the local toggle cache
     * @param eagerInit       whether to load toggles eagerly on initialization
     * @param errorListener      callback for errors swallowed by {@code isEnabled()}, or {@code null}
     * @param defaultEnvironment default environment for single-arg {@code isEnabled()}, or {@code null}
     * @param readyListener      callback invoked after successful initialization, or {@code null}
     * @param serviceName        service name for X-Togli-Service header, must not be {@code null} or blank
     * @param namespace          Kubernetes namespace for X-Togli-Namespace header, or {@code null}
     */
    public TogliConfiguration(
            String baseUrl,
            String apiKey,
            String projectSlug,
            Duration pollingInterval,
            Duration requestTimeout,
            Duration connectTimeout,
            boolean cacheEnabled,
            boolean eagerInit,
            Consumer<TogliException> errorListener,
            String defaultEnvironment,
            Consumer<TogliClient> readyListener,
            String serviceName,
            String namespace
    ) {
        Objects.requireNonNull(baseUrl, "baseUrl must not be null");
        if (baseUrl.isBlank()) {
            throw new IllegalArgumentException("baseUrl must not be blank");
        }
        Objects.requireNonNull(apiKey, "apiKey must not be null");
        if (apiKey.isBlank()) {
            throw new IllegalArgumentException("apiKey must not be blank");
        }
        Objects.requireNonNull(projectSlug, "projectSlug must not be null");
        if (projectSlug.isBlank()) {
            throw new IllegalArgumentException("projectSlug must not be blank");
        }

        this.baseUrl = baseUrl;
        this.apiKey = apiKey;
        this.projectSlug = projectSlug;
        this.pollingInterval = pollingInterval != null ? pollingInterval : DEFAULT_POLLING_INTERVAL;
        this.requestTimeout = requestTimeout != null ? requestTimeout : DEFAULT_REQUEST_TIMEOUT;
        this.connectTimeout = connectTimeout != null ? connectTimeout : DEFAULT_CONNECT_TIMEOUT;
        this.cacheEnabled = cacheEnabled;
        this.eagerInit = eagerInit;
        this.errorListener = errorListener;
        this.defaultEnvironment = defaultEnvironment;
        this.readyListener = readyListener;

        Objects.requireNonNull(serviceName, "serviceName must not be null");
        if (serviceName.isBlank()) {
            throw new IllegalArgumentException("serviceName must not be blank");
        }
        this.serviceName = serviceName;
        this.namespace = namespace;

        if (this.cacheEnabled && this.pollingInterval.compareTo(MIN_POLLING_INTERVAL) < 0) {
            throw new IllegalArgumentException(
                    "pollingInterval must be at least 5 seconds when cache is enabled, got "
                            + this.pollingInterval);
        }
    }
}
