/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

/**
 * Pagination metadata for paged API responses.
 *
 * @param page          zero-based page index, must be &gt;= 0
 * @param size          page size, must be &gt;= 1
 * @param totalElements total number of elements across all pages
 * @param totalPages    total number of pages
 */
public record Pagination(int page, int size, long totalElements, int totalPages) {

    /**
     * Creates new pagination metadata after validating invariants.
     */
    public Pagination {
        if (page < 0) {
            throw new IllegalArgumentException("page must be >= 0, got " + page);
        }
        if (size < 1) {
            throw new IllegalArgumentException("size must be >= 1, got " + size);
        }
    }
}
