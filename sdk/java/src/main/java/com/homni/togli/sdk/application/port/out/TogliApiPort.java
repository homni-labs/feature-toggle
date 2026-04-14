/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.application.port.out;

import com.homni.togli.sdk.domain.model.EnvironmentPage;
import com.homni.togli.sdk.domain.model.ProjectInfo;
import com.homni.togli.sdk.domain.model.Toggle;
import com.homni.togli.sdk.domain.model.TogglePage;

/**
 * Outbound port for communicating with the Togli REST API.
 *
 * <p>Implementations translate HTTP responses into domain model objects and
 * translate HTTP error codes into typed SDK exceptions. A single instance
 * is shared across the polling cache and the client; implementations must
 * be thread-safe.
 */
public interface TogliApiPort {

    /**
     * Fetches project information by its URL-friendly slug.
     *
     * @param slug the project slug, must not be {@code null} or blank
     * @return the project info, never {@code null}
     * @throws com.homni.togli.sdk.domain.exception.TogliNotFoundException       if the project does not exist
     * @throws com.homni.togli.sdk.domain.exception.TogliAuthenticationException if the API key is invalid
     * @throws com.homni.togli.sdk.domain.exception.TogliAccessDeniedException   if permissions are insufficient
     * @throws com.homni.togli.sdk.domain.exception.TogliNetworkException        on network-level errors
     */
    ProjectInfo fetchProjectBySlug(String slug);

    /**
     * Fetches a page of feature toggles for the given project.
     *
     * @param projectId the project identifier, must not be {@code null} or blank
     * @param page      zero-based page index, must be &gt;= 0
     * @param size      page size, must be &gt;= 1
     * @return a page of toggles with pagination metadata, never {@code null}
     * @throws com.homni.togli.sdk.domain.exception.TogliAuthenticationException if the API key is invalid
     * @throws com.homni.togli.sdk.domain.exception.TogliAccessDeniedException   if permissions are insufficient
     * @throws com.homni.togli.sdk.domain.exception.TogliNetworkException        on network-level errors
     */
    TogglePage fetchToggles(String projectId, int page, int size);

    /**
     * Fetches a single feature toggle by its identifier.
     *
     * @param projectId the project identifier, must not be {@code null} or blank
     * @param toggleId  the toggle identifier, must not be {@code null} or blank
     * @return the toggle with its per-environment states, never {@code null}
     * @throws com.homni.togli.sdk.domain.exception.TogliNotFoundException       if the toggle does not exist
     * @throws com.homni.togli.sdk.domain.exception.TogliAuthenticationException if the API key is invalid
     * @throws com.homni.togli.sdk.domain.exception.TogliAccessDeniedException   if permissions are insufficient
     * @throws com.homni.togli.sdk.domain.exception.TogliNetworkException        on network-level errors
     */
    Toggle fetchToggle(String projectId, String toggleId);

    /**
     * Fetches a page of environments for the given project.
     *
     * @param projectId the project identifier, must not be {@code null} or blank
     * @param page      zero-based page index, must be &gt;= 0
     * @param size      page size, must be &gt;= 1
     * @return a page of environments with pagination metadata, never {@code null}
     * @throws com.homni.togli.sdk.domain.exception.TogliAuthenticationException if the API key is invalid
     * @throws com.homni.togli.sdk.domain.exception.TogliAccessDeniedException   if permissions are insufficient
     * @throws com.homni.togli.sdk.domain.exception.TogliNetworkException        on network-level errors
     */
    EnvironmentPage fetchEnvironments(String projectId, int page, int size);
}
