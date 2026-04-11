/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.port.out;

import com.homni.featuretoggle.application.usecase.ProjectListItem;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.ProjectSlug;
import com.homni.featuretoggle.domain.model.UserId;

import java.util.List;
import java.util.Optional;

/**
 * Output port for persisting projects.
 */
public interface ProjectRepositoryPort {

    /**
     * Saves a project (insert or update).
     *
     * @param project the project to save
     */
    void save(Project project);

    /**
     * Finds a project by identity.
     *
     * @param id project identity
     * @return the project if found, or empty
     */
    Optional<Project> findById(ProjectId id);

    /**
     * Finds a project by its unique slug.
     *
     * @param slug the project slug
     * @return the project if found, or empty
     */
    Optional<Project> findBySlug(ProjectSlug slug);

    /**
     * Returns a page of projects visible to the caller, pre-aggregated with
     * per-project counts (toggles, environments, members) and the caller's
     * role in each project.
     *
     * <p>Visibility rules: {@code platformAdmin == true} sees every project
     * (including archived ones). Otherwise the caller sees only projects they
     * are a member of, with archived projects further restricted to those
     * where their role is {@code ADMIN}.
     *
     * <p>Filters compose on top of the visibility rules:
     * <ul>
     *     <li>{@code searchText} — case-insensitive substring match against
     *         the project name and slug. {@code null} or blank disables it.</li>
     *     <li>{@code archived} — tri-state filter; {@code null} returns both,
     *         {@code true} only archived, {@code false} only active.</li>
     * </ul>
     *
     * @param callerUserId    the caller's user identity
     * @param platformAdmin   whether the caller has platform-admin privileges
     * @param searchText      optional case-insensitive substring filter on
     *                        name/slug, or {@code null}
     * @param archived        optional archived filter, or {@code null} for both
     * @param offset          rows to skip
     * @param limit           max rows to return
     * @return matching projects with role + counts, ordered by name
     */
    List<ProjectListItem> findPage(UserId callerUserId,
                                   boolean platformAdmin,
                                   String searchText,
                                   Boolean archived,
                                   int offset,
                                   int limit);

    /**
     * Counts projects visible to the caller, applying the same visibility
     * rules and optional filters as {@link #findPage}. Used both for the
     * pagination envelope (with active filters) and for the workspace-level
     * subtitle counters (with filters set to {@code null}).
     *
     * @param callerUserId    the caller's user identity
     * @param platformAdmin   whether the caller has platform-admin privileges
     * @param searchText      optional case-insensitive substring filter on
     *                        name/slug, or {@code null}
     * @param archived        optional archived filter, or {@code null} for both
     * @return matching project count
     */
    long countMatching(UserId callerUserId,
                       boolean platformAdmin,
                       String searchText,
                       Boolean archived);
}
