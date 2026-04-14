/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.DomainValidationException;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * Platform-wide list of "default" environment names that can be bootstrapped
 * into a new project at creation. Always-valid value object: each name is
 * normalized via {@link Environment#validateAndNormalize(String)} and
 * deduplicated at construction, so an instance is guaranteed to hold a clean,
 * unique list of well-formed names.
 */
public final class EnvironmentDefaults {

    private final List<String> names;

    /**
     * Builds and validates the defaults from raw config input.
     *
     * @param rawNames names as configured in {@code app.environments.defaults}
     * @throws DomainValidationException if any name is invalid or duplicates another
     */
    public EnvironmentDefaults(List<String> rawNames) {
        Objects.requireNonNull(rawNames, "rawNames must not be null");
        List<String> normalized = new ArrayList<>(rawNames.size());
        for (String raw : rawNames) {
            String value = Environment.validateAndNormalize(raw);
            if (normalized.contains(value)) {
                throw new DomainValidationException(
                        "Duplicate default environment name '%s'".formatted(value));
            }
            normalized.add(value);
        }
        this.names = List.copyOf(normalized);
    }

    /**
     * @return all configured default names, in config order
     */
    public List<String> all() {
        return this.names;
    }

    /**
     * @return {@code true} if no defaults are configured
     */
    public boolean isEmpty() {
        return this.names.isEmpty();
    }

    /**
     * Resolves the caller's selection into a concrete list of {@link Environment}
     * instances scoped to the given project. Three-mode semantics:
     * <ul>
     *   <li>{@code null} — bootstrap all configured defaults</li>
     *   <li>empty list — explicit opt-out, no environments are created</li>
     *   <li>non-empty list — only the listed names; each must be in the
     *       configured defaults, otherwise the request is rejected</li>
     * </ul>
     * Duplicate or null entries in the input are silently collapsed.
     *
     * @param projectId owning project identity
     * @param selected  caller's selection, or {@code null} for all
     * @return environment instances ready to be persisted
     * @throws DomainValidationException if any selected name is not in the defaults
     */
    public List<Environment> bootstrapFor(ProjectId projectId, List<String> selected) {
        Objects.requireNonNull(projectId, "projectId must not be null");
        List<String> resolved = resolveNames(selected);
        List<Environment> envs = new ArrayList<>(resolved.size());
        for (String name : resolved) {
            envs.add(new Environment(projectId, name));
        }
        return envs;
    }

    private List<String> resolveNames(List<String> selected) {
        if (selected == null) {
            return this.names;
        }
        if (selected.isEmpty()) {
            return List.of();
        }
        List<String> result = new ArrayList<>(selected.size());
        for (String raw : selected) {
            String normalized = Environment.validateAndNormalize(raw);
            if (!this.names.contains(normalized)) {
                throw new DomainValidationException(
                        "Environment '%s' is not in the configured platform defaults".formatted(raw));
            }
            if (!result.contains(normalized)) {
                result.add(normalized);
            }
        }
        return result;
    }
}
