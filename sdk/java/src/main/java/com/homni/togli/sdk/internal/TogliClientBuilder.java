/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.internal;

import com.homni.togli.sdk.TogliClient;
import com.homni.togli.sdk.application.port.out.TogliApiPort;
import com.homni.togli.sdk.domain.model.ProjectInfo;
import com.homni.togli.sdk.infrastructure.cache.CacheFactory;
import com.homni.togli.sdk.infrastructure.cache.ToggleCache;
import com.homni.togli.sdk.infrastructure.config.TogliConfiguration;
import com.homni.togli.sdk.infrastructure.http.HttpTogliApiAdapter;

import com.homni.togli.sdk.domain.exception.TogliException;

import java.time.Duration;
import java.util.Objects;
import java.util.function.Consumer;

/**
 * Fluent builder for constructing a {@link TogliClient}.
 *
 * <p>Required fields: {@link #baseUrl(String)}, {@link #apiKey(String)}, and
 * {@link #projectSlug(String)}. All other settings have sensible defaults.
 *
 * <pre>{@code
 * TogliClient client = new TogliClientBuilder()
 *         .baseUrl("https://api.togli.io")
 *         .apiKey("tok_live_abc123")
 *         .projectSlug("my-project")
 *         .pollingInterval(Duration.ofMinutes(5))
 *         .build();
 * }</pre>
 */
public final class TogliClientBuilder {

    private String baseUrl;
    private String apiKey;
    private String projectSlug;
    private Duration pollingInterval = Duration.ofHours(1);
    private Duration requestTimeout = Duration.ofSeconds(10);
    private Duration connectTimeout = Duration.ofSeconds(5);
    private boolean cacheEnabled = true;
    private boolean eagerInit = true;
    private Consumer<TogliException> errorListener;
    private String defaultEnvironment;
    private Consumer<TogliClient> readyListener;

    /**
     * Creates a new builder with default settings.
     */
    public TogliClientBuilder() {
    }

    /**
     * Sets the base URL of the Togli API.
     *
     * @param baseUrl the base URL, must not be {@code null} or blank
     * @return this builder
     */
    public TogliClientBuilder baseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
        return this;
    }

    /**
     * Sets the API key for authentication.
     *
     * @param apiKey the API key, must not be {@code null} or blank
     * @return this builder
     */
    public TogliClientBuilder apiKey(String apiKey) {
        this.apiKey = apiKey;
        return this;
    }

    /**
     * Sets the project slug used to resolve the project on the server.
     *
     * @param slug the project slug, must not be {@code null} or blank
     * @return this builder
     */
    public TogliClientBuilder projectSlug(String slug) {
        this.projectSlug = slug;
        return this;
    }

    /**
     * Sets the interval between background cache refresh polls.
     * Default: 1 hour.
     *
     * @param interval the polling interval, must not be {@code null}
     * @return this builder
     */
    public TogliClientBuilder pollingInterval(Duration interval) {
        this.pollingInterval = Objects.requireNonNull(interval, "pollingInterval must not be null");
        return this;
    }

    /**
     * Sets the HTTP request timeout. Default: 10 seconds.
     *
     * @param timeout the request timeout, must not be {@code null}
     * @return this builder
     */
    public TogliClientBuilder requestTimeout(Duration timeout) {
        this.requestTimeout = Objects.requireNonNull(timeout, "requestTimeout must not be null");
        return this;
    }

    /**
     * Sets the HTTP connection timeout. Default: 5 seconds.
     *
     * @param timeout the connection timeout, must not be {@code null}
     * @return this builder
     */
    public TogliClientBuilder connectTimeout(Duration timeout) {
        this.connectTimeout = Objects.requireNonNull(timeout, "connectTimeout must not be null");
        return this;
    }

    /**
     * Disables the background polling cache. Toggles will be fetched
     * directly from the API on every evaluation.
     *
     * @return this builder
     */
    public TogliClientBuilder cacheDisabled() {
        this.cacheEnabled = false;
        return this;
    }

    /**
     * Registers a listener that is called when {@code isEnabled()} catches
     * and swallows an error. The listener receives the original exception
     * without affecting the return value ({@code false}).
     *
     * <p>Use this to log errors, send them to monitoring, etc.
     *
     * <pre>{@code
     * .onError(error -> logger.warn("Toggle evaluation failed: {}", error.getMessage()))
     * }</pre>
     *
     * @param listener the error callback, must not be {@code null}
     * @return this builder
     */
    public TogliClientBuilder onError(Consumer<TogliException> listener) {
        this.errorListener = Objects.requireNonNull(listener, "errorListener must not be null");
        return this;
    }

    /**
     * Sets the default environment used by {@link TogliClient#isEnabled(String)}.
     *
     * <p>When set, you can call {@code client.isEnabled("toggle-name")} without
     * specifying the environment every time.
     *
     * @param environment the default environment name (e.g. "PROD"), must not be {@code null}
     * @return this builder
     */
    public TogliClientBuilder defaultEnvironment(String environment) {
        this.defaultEnvironment = Objects.requireNonNull(environment, "defaultEnvironment must not be null");
        return this;
    }

    /**
     * Registers a callback invoked once after the client is fully initialized
     * (project resolved, toggles loaded). Useful for logging or metrics.
     *
     * <pre>{@code
     * .onReady(client -> logger.info("Togli SDK loaded {} toggles", client.allToggles().size()))
     * }</pre>
     *
     * @param listener the ready callback, must not be {@code null}
     * @return this builder
     */
    public TogliClientBuilder onReady(Consumer<TogliClient> listener) {
        this.readyListener = Objects.requireNonNull(listener, "readyListener must not be null");
        return this;
    }

    /**
     * Controls whether the cache performs an initial synchronous fetch
     * during {@link #build()}. Default: {@code true}.
     *
     * @param eager {@code true} to fetch eagerly, {@code false} to defer
     * @return this builder
     */
    public TogliClientBuilder eagerInit(boolean eager) {
        this.eagerInit = eager;
        return this;
    }

    /**
     * Validates configuration, resolves the project by slug (validating the
     * API key in the process), initializes the cache, and returns a fully
     * configured {@link TogliClient}.
     *
     * @return a ready-to-use client, never {@code null}
     * @throws IllegalStateException if required fields are missing or blank
     * @throws com.homni.togli.sdk.domain.exception.TogliAuthenticationException if the API key is invalid
     * @throws com.homni.togli.sdk.domain.exception.TogliNotFoundException       if the project slug does not exist
     * @throws com.homni.togli.sdk.domain.exception.TogliNetworkException        on network-level errors
     */
    public TogliClient build() {
        validateRequired(baseUrl, "baseUrl");
        validateRequired(apiKey, "apiKey");
        validateRequired(projectSlug, "projectSlug");

        TogliConfiguration config = new TogliConfiguration(
                baseUrl, apiKey, projectSlug,
                pollingInterval, requestTimeout, connectTimeout,
                cacheEnabled, eagerInit, errorListener,
                defaultEnvironment, readyListener
        );

        TogliApiPort api = new HttpTogliApiAdapter(config);

        // Resolves project by slug — also validates the API key (401 = fail fast)
        ProjectInfo project = api.fetchProjectBySlug(projectSlug);

        ToggleCache cache = CacheFactory.create(api, project.id, config);

        DefaultTogliClient client = new DefaultTogliClient(api, cache, project, config);

        if (readyListener != null) {
            readyListener.accept(client);
        }

        return client;
    }

    /**
     * Validates that a required string field is neither null nor blank.
     *
     * @param value the value to validate
     * @param name  the field name for the error message
     */
    private static void validateRequired(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalStateException(name + " must not be null or blank");
        }
    }
}
