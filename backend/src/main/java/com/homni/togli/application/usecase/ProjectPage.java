/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import java.util.List;
import java.util.Objects;

/**
 * Paginated project list with workspace-level totals.
 *
 * <p>{@code totalElements} reflects the search/archived-filtered query — it is
 * what the pagination UI consumes. {@code totalCount} and {@code archivedCount}
 * are workspace-wide visible counts that ignore the query filters; the page
 * header subtitle uses them to render "N projects · M archived" without an
 * extra round-trip.
 *
 * @param items          projects on this page (already filtered + paginated)
 * @param totalElements  total number of items matching the active filters
 * @param totalCount     total number of projects visible in the workspace,
 *                       ignoring search and archived filters
 * @param archivedCount  number of archived projects visible in the workspace,
 *                       ignoring search and archived filters
 */
public record ProjectPage(
        List<ProjectListItem> items,
        long totalElements,
        long totalCount,
        long archivedCount) {

    /** Defensive copy of items. */
    public ProjectPage {
        Objects.requireNonNull(items, "items must not be null");
        items = List.copyOf(items);
    }

    /**
     * Assembles a project page, applying caller-specific view rules.
     *
     * <p>When the caller is a platform admin, per-project roles are masked
     * ({@code myRole = null}) because PA access is implicit and the
     * per-project role is meaningless in that view.
     *
     * @param items             raw items from the repository
     * @param totalElements     filtered total for pagination envelope
     * @param totalCount        workspace-wide visible project count
     * @param archivedCount     workspace-wide archived count
     * @param callerIsPlatformAdmin whether the caller has platform-admin privileges
     * @return assembled page with caller-appropriate role visibility
     */
    public static ProjectPage create(List<ProjectListItem> items,
                                     long totalElements,
                                     long totalCount,
                                     long archivedCount,
                                     boolean callerIsPlatformAdmin) {
        var displayItems = callerIsPlatformAdmin
                ? items.stream().map(ProjectListItem::withoutProjectRole).toList()
                : items;
        return new ProjectPage(displayItems, totalElements, totalCount, archivedCount);
    }
}
