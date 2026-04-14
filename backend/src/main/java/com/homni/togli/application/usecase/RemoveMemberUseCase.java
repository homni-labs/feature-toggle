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
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.ProjectArchivedException;
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.UserId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Removes a member from a project.
 */
public final class RemoveMemberUseCase {

    private static final Logger log = LoggerFactory.getLogger(RemoveMemberUseCase.class);

    private final ProjectMembershipRepositoryPort memberships;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param memberships  membership persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public RemoveMemberUseCase(ProjectMembershipRepositoryPort memberships,
                               ProjectRepositoryPort projects,
                               CallerProjectAccessPort callerAccess) {
        this.memberships = memberships;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Removes a user from a project.
     *
     * @param projectId project identity
     * @param userId    user identity to remove
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the project does not exist
     */
    public void execute(ProjectId projectId, UserId userId) {
        log.debug("Removing member: project={}, user={}", projectId.value, userId.value);
        callerAccess.resolve(projectId).ensure(Permission.MANAGE_MEMBERS);
        projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value))
                .ensureNotArchived();
        memberships.deleteByProjectAndUser(projectId, userId);
    }
}
