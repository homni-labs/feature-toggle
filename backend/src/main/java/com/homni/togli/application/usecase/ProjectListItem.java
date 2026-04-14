/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectRole;

/**
 * Project list row pre-aggregated for the list UI.
 *
 * <p>Counts are computed in a single SQL query alongside the project rows so
 * the projects screen can render its workspace cards (name, slug, role badge,
 * counters) without N + 1 follow-up requests.
 *
 * @param project           the project
 * @param myRole            caller's role in this project, or {@code null} for
 *                          platform admins (who have implicit access to every
 *                          project regardless of membership)
 * @param togglesCount      number of feature toggles in this project
 * @param environmentsCount number of environments in this project
 * @param membersCount      number of members in this project
 */
public record ProjectListItem(
        Project project,
        ProjectRole myRole,
        long togglesCount,
        long environmentsCount,
        long membersCount) {

    /**
     * Returns a copy with {@code myRole} set to {@code null}.
     *
     * <p>Platform admins have implicit access to every project — the per-project
     * role is meaningless in that context and must not leak to the API consumer.
     */
    public ProjectListItem withoutProjectRole() {
        return new ProjectListItem(project, null, togglesCount, environmentsCount, membersCount);
    }
}
