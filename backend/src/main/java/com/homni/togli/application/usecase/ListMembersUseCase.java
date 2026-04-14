/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectMembership;

import java.util.List;

/**
 * Lists project members with pagination.
 */
public final class ListMembersUseCase {

    private final ProjectMembershipRepositoryPort memberships;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param memberships  membership persistence port
     * @param callerAccess caller's project access resolver
     */
    public ListMembersUseCase(ProjectMembershipRepositoryPort memberships,
                               CallerProjectAccessPort callerAccess) {
        this.memberships = memberships;
        this.callerAccess = callerAccess;
    }

    /**
     * Lists members of a project.
     *
     * @param projectId project identity
     * @param page      zero-based page number
     * @param size      page size
     * @return a page of memberships
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks READ_TOGGLES
     */
    public MemberPage execute(ProjectId projectId, int page, int size) {
        callerAccess.resolve(projectId).ensure(Permission.READ_TOGGLES);
        int offset = page * size;
        List<ProjectMembership> items = memberships.findByProject(projectId, offset, size);
        long total = memberships.countByProject(projectId);
        return new MemberPage(items, total);
    }
}
