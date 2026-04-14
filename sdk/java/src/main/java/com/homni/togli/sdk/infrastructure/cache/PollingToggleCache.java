/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.cache;

import com.homni.togli.sdk.application.port.out.TogliApiPort;
import com.homni.togli.sdk.domain.model.Toggle;
import com.homni.togli.sdk.domain.model.TogglePage;

import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * A polling-based cache that periodically refreshes toggles from the Togli API.
 *
 * <p>Uses a single daemon thread to poll at a configurable interval. The cache
 * is fully thread-safe: reads use a volatile reference to an immutable map,
 * ensuring that concurrent readers never see a partially-updated state.
 */
final class PollingToggleCache implements ToggleCache {

    private static final int PAGE_SIZE = 100;

    private volatile Map<String, Toggle> togglesByName = Map.of();

    private final ScheduledExecutorService scheduler;
    private final TogliApiPort api;
    private final String projectId;
    private final Duration pollingInterval;
    private final System.Logger logger;

    /**
     * Creates a new polling cache.
     *
     * @param api             the API port used to fetch toggles, must not be {@code null}
     * @param projectId       the project identifier to poll, must not be {@code null} or blank
     * @param pollingInterval the interval between polls, must not be {@code null}
     */
    PollingToggleCache(TogliApiPort api, String projectId, Duration pollingInterval) {
        this.api = Objects.requireNonNull(api, "api must not be null");
        Objects.requireNonNull(projectId, "projectId must not be null");
        if (projectId.isBlank()) {
            throw new IllegalArgumentException("projectId must not be blank");
        }
        this.projectId = projectId;
        this.pollingInterval = Objects.requireNonNull(pollingInterval, "pollingInterval must not be null");
        this.logger = System.getLogger(PollingToggleCache.class.getName());
        this.scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread thread = new Thread(r, "togli-cache-poller");
            thread.setDaemon(true);
            return thread;
        });
    }

    /**
     * {@inheritDoc}
     *
     * <p>Looks up the toggle by name in the volatile snapshot map.
     */
    @Override
    public Optional<Toggle> findByName(String name) {
        return Optional.ofNullable(togglesByName.get(name));
    }

    /**
     * {@inheritDoc}
     *
     * <p>Returns an unmodifiable copy of all cached toggle values.
     */
    @Override
    public List<Toggle> all() {
        return List.copyOf(togglesByName.values());
    }

    /**
     * {@inheritDoc}
     *
     * <p>Atomically replaces the cache content with an immutable snapshot
     * built from the given toggle list, keyed by {@link Toggle#name}.
     */
    @Override
    public void refresh(List<Toggle> toggles) {
        Map<String, Toggle> newMap = new LinkedHashMap<>();
        for (Toggle toggle : toggles) {
            newMap.put(toggle.name, toggle);
        }
        this.togglesByName = Map.copyOf(newMap);
    }

    /**
     * {@inheritDoc}
     *
     * <p>Performs an initial synchronous fetch of all toggles, then schedules
     * periodic background refreshes at the configured polling interval.
     */
    @Override
    public void start() {
        fetchAllToggles();
        scheduler.scheduleAtFixedRate(
                this::refreshTask,
                pollingInterval.toMillis(),
                pollingInterval.toMillis(),
                TimeUnit.MILLISECONDS
        );
    }

    /**
     * {@inheritDoc}
     *
     * <p>Shuts down the scheduler gracefully, waiting up to 5 seconds for
     * in-flight tasks to complete before forcing a shutdown.
     */
    @Override
    public void stop() {
        scheduler.shutdown();
        try {
            if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                scheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            scheduler.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }

    /**
     * Fetches all toggles from the API by paginating through every page,
     * then atomically refreshes the cache.
     *
     * <p>On failure, a warning is logged and the stale cache is preserved.
     */
    private void fetchAllToggles() {
        try {
            List<Toggle> allToggles = new ArrayList<>();
            int page = 0;
            int totalPages;

            do {
                TogglePage result = api.fetchToggles(projectId, page, PAGE_SIZE);
                allToggles.addAll(result.items());
                totalPages = result.pagination().totalPages();
                page++;
            } while (page < totalPages);

            refresh(allToggles);
        } catch (Exception e) {
            logger.log(System.Logger.Level.WARNING, "Failed to fetch toggles, keeping stale cache", e);
        }
    }

    /**
     * Scheduled refresh task that delegates to {@link #fetchAllToggles()},
     * catching and logging any exceptions to prevent the scheduler from stopping.
     */
    private void refreshTask() {
        try {
            fetchAllToggles();
        } catch (Exception e) {
            logger.log(System.Logger.Level.WARNING, "Refresh failed", e);
        }
    }
}
