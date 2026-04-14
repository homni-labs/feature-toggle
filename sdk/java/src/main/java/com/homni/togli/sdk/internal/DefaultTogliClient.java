/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.internal;

import com.homni.togli.sdk.TogliClient;
import com.homni.togli.sdk.application.port.out.TogliApiPort;
import com.homni.togli.sdk.domain.exception.TogliException;
import com.homni.togli.sdk.domain.exception.TogliNotFoundException;
import com.homni.togli.sdk.domain.model.EnvironmentInfo;
import com.homni.togli.sdk.domain.model.EnvironmentPage;
import com.homni.togli.sdk.domain.model.ProjectInfo;
import com.homni.togli.sdk.domain.model.Toggle;
import com.homni.togli.sdk.domain.model.TogglePage;
import com.homni.togli.sdk.infrastructure.cache.ToggleCache;
import com.homni.togli.sdk.infrastructure.config.TogliConfiguration;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * Default implementation of {@link TogliClient}.
 *
 * <p>Delegates toggle lookups to the {@link ToggleCache} when caching is
 * enabled, and falls back to direct API calls otherwise. This class is
 * thread-safe: all fields are {@code final} and the cache provides
 * atomic read/write semantics.
 */
final class DefaultTogliClient implements TogliClient {

    private static final int PAGE_SIZE = 100;

    private final TogliApiPort api;
    private final ToggleCache cache;
    private final ProjectInfo project;
    private final TogliConfiguration config;
    private final Thread shutdownHook;

    /**
     * Creates a new client and registers a JVM shutdown hook that
     * automatically stops the background polling thread on application exit.
     *
     * @param api     the API port for direct calls, must not be {@code null}
     * @param cache   the toggle cache, must not be {@code null}
     * @param project the resolved project info, must not be {@code null}
     * @param config  the SDK configuration, must not be {@code null}
     */
    DefaultTogliClient(TogliApiPort api, ToggleCache cache, ProjectInfo project, TogliConfiguration config) {
        this.api = Objects.requireNonNull(api, "api must not be null");
        this.cache = Objects.requireNonNull(cache, "cache must not be null");
        this.project = Objects.requireNonNull(project, "project must not be null");
        this.config = Objects.requireNonNull(config, "config must not be null");

        this.shutdownHook = new Thread(cache::stop, "togli-shutdown");
        Runtime.getRuntime().addShutdownHook(this.shutdownHook);
    }

    /**
     * {@inheritDoc}
     *
     * @throws IllegalStateException if no default environment is configured
     */
    @Override
    public boolean isEnabled(String toggleName) {
        if (config.defaultEnvironment == null) {
            throw new IllegalStateException(
                    "No default environment configured. Use .defaultEnvironment(\"PROD\") in the builder, "
                    + "or call isEnabled(toggleName, environmentName) instead.");
        }
        return isEnabled(toggleName, config.defaultEnvironment);
    }

    /**
     * {@inheritDoc}
     *
     * <p>Returns {@code false} if the toggle is not found, if the environment
     * is not assigned, or if any error occurs.
     */
    @Override
    public boolean isEnabled(String toggleName, String environmentName) {
        Objects.requireNonNull(toggleName, "toggleName must not be null");
        Objects.requireNonNull(environmentName, "environmentName must not be null");

        try {
            Optional<Toggle> toggle = config.cacheEnabled
                    ? cache.findByName(toggleName)
                    : fetchAllFromApi().stream()
                            .filter(t -> t.name.equals(toggleName))
                            .findFirst();

            return toggle.map(t -> t.isEnabledIn(environmentName)).orElse(false);
        } catch (TogliException e) {
            notifyErrorListener(e);
            return false;
        }
    }

    /**
     * {@inheritDoc}
     *
     * @throws TogliNotFoundException if the toggle is not found
     */
    @Override
    public Toggle toggle(String toggleName) {
        Objects.requireNonNull(toggleName, "toggleName must not be null");

        if (config.cacheEnabled) {
            return cache.findByName(toggleName)
                    .orElseThrow(() -> new TogliNotFoundException("Toggle", toggleName));
        }

        return fetchAllFromApi().stream()
                .filter(t -> t.name.equals(toggleName))
                .findFirst()
                .orElseThrow(() -> new TogliNotFoundException("Toggle", toggleName));
    }

    /** {@inheritDoc} */
    @Override
    public List<Toggle> allToggles() {
        if (config.cacheEnabled) {
            return cache.all();
        }
        return fetchAllFromApi();
    }

    /** {@inheritDoc} */
    @Override
    public List<EnvironmentInfo> allEnvironments() {
        List<EnvironmentInfo> all = new ArrayList<>();
        int page = 0;
        int totalPages;

        do {
            EnvironmentPage result = api.fetchEnvironments(project.id, page, PAGE_SIZE);
            all.addAll(result.items());
            totalPages = result.pagination().totalPages();
            page++;
        } while (page < totalPages);

        return List.copyOf(all);
    }

    /** {@inheritDoc} */
    @Override
    public ProjectInfo projectInfo() {
        return project;
    }

    /** {@inheritDoc} */
    @Override
    public void refresh() {
        if (config.cacheEnabled) {
            cache.refresh(fetchAllFromApi());
        }
    }

    /** {@inheritDoc} */
    @Override
    public void close() {
        cache.stop();
        try {
            Runtime.getRuntime().removeShutdownHook(this.shutdownHook);
        } catch (IllegalStateException ignored) {
            // JVM is already shutting down
        }
    }

    /**
     * Notifies the error listener if one is configured.
     *
     * @param exception the error that was swallowed
     */
    private void notifyErrorListener(TogliException exception) {
        if (config.errorListener != null) {
            try {
                config.errorListener.accept(exception);
            } catch (Exception ignored) {
                // listener must not break the SDK
            }
        }
    }

    /**
     * Fetches all toggles from the API by paginating through every page.
     *
     * @return an unmodifiable list of all toggles
     */
    private List<Toggle> fetchAllFromApi() {
        List<Toggle> all = new ArrayList<>();
        int page = 0;
        int totalPages;

        do {
            TogglePage result = api.fetchToggles(project.id, page, PAGE_SIZE);
            all.addAll(result.items());
            totalPages = result.pagination().totalPages();
            page++;
        } while (page < totalPages);

        return List.copyOf(all);
    }
}
