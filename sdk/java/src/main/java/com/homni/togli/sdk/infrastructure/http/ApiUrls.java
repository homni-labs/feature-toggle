/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.http;

/**
 * URL path builder for the Togli REST API.
 *
 * <p>All methods return a fully-qualified URL string composed from the
 * configured base URL and the appropriate path segments.
 */
final class ApiUrls {

    private final String baseUrl;

    /**
     * Creates a new URL builder rooted at the given base URL.
     *
     * @param baseUrl the API base URL (trailing slash is trimmed)
     */
    ApiUrls(String baseUrl) {
        if (baseUrl == null || baseUrl.isBlank()) {
            throw new IllegalArgumentException("baseUrl must not be null or blank");
        }
        this.baseUrl = baseUrl.endsWith("/")
                ? baseUrl.substring(0, baseUrl.length() - 1)
                : baseUrl;
    }

    /**
     * Returns the URL to look up a project by its slug.
     *
     * @param slug the project slug
     * @return the full URL path
     */
    String projectBySlug(String slug) {
        return baseUrl + "/projects/by-slug/" + slug;
    }

    /**
     * Returns the URL to list toggles for a project with pagination.
     *
     * @param projectId the project identifier
     * @param page      zero-based page index
     * @param size      page size
     * @return the full URL path with query parameters
     */
    String toggles(String projectId, int page, int size) {
        return baseUrl + "/projects/" + projectId + "/toggles?page=" + page + "&size=" + size;
    }

    /**
     * Returns the URL to fetch a single toggle.
     *
     * @param projectId the project identifier
     * @param toggleId  the toggle identifier
     * @return the full URL path
     */
    String toggle(String projectId, String toggleId) {
        return baseUrl + "/projects/" + projectId + "/toggles/" + toggleId;
    }

    /**
     * Returns the URL to list environments for a project with pagination.
     *
     * @param projectId the project identifier
     * @param page      zero-based page index
     * @param size      page size
     * @return the full URL path with query parameters
     */
    String environments(String projectId, int page, int size) {
        return baseUrl + "/projects/" + projectId + "/environments?page=" + page + "&size=" + size;
    }
}
