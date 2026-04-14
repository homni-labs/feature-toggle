/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.CallerPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.model.AppUser;

import java.util.List;

/**
 * Lists projects visible to the calling user with filtering, search and
 * pagination.
 */
public final class ListProjectsUseCase {

    private final ProjectRepositoryPort projects;
    private final CallerPort callerPort;

    /**
     * @param projects   project persistence port
     * @param callerPort authenticated caller provider
     */
    public ListProjectsUseCase(ProjectRepositoryPort projects, CallerPort callerPort) {
        this.projects = projects;
        this.callerPort = callerPort;
    }

    /**
     * Lists projects accessible to the caller, optionally filtered by name/slug
     * search and archived state, paginated.
     *
     * <p>The returned page also carries workspace-level totals
     * ({@code totalCount} and {@code archivedCount}) computed against the same
     * visibility rules but ignoring the search/archived query parameters, so
     * the page header subtitle ("N projects · M archived") stays stable while
     * the user filters or searches.
     *
     * @param searchText optional case-insensitive name/slug substring filter
     * @param archived   optional archived filter ({@code null} = both)
     * @param page       zero-based page number
     * @param size       page size
     * @return a page of matching projects with role and counts
     */
    public ProjectPage execute(String searchText, Boolean archived, int page, int size) {
        AppUser caller = callerPort.get();
        boolean pa = caller.isPlatformAdmin();
        int offset = page * size;

        List<ProjectListItem> items = projects.findPage(
                caller.id, pa, searchText, archived, offset, size);

        long totalElements = projects.countMatching(caller.id, pa, searchText, archived);
        long totalCount    = projects.countMatching(caller.id, pa, null, null);
        long archivedCount = projects.countMatching(caller.id, pa, null, true);

        return ProjectPage.create(items, totalElements, totalCount, archivedCount, pa);
    }
}
