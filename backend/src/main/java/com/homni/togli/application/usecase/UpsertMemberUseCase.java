/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.AppUserRepositoryPort;
import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.ProjectArchivedException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.UserId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Optional;

/**
 * Adds a user to a project or updates their role (upsert semantics).
 */
public final class UpsertMemberUseCase {

    private static final Logger log = LoggerFactory.getLogger(UpsertMemberUseCase.class);

    private final ProjectMembershipRepositoryPort memberships;
    private final AppUserRepositoryPort users;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param memberships  membership persistence port
     * @param users        user persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public UpsertMemberUseCase(ProjectMembershipRepositoryPort memberships,
                               AppUserRepositoryPort users,
                               ProjectRepositoryPort projects,
                               CallerProjectAccessPort callerAccess) {
        this.memberships = memberships;
        this.users = users;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Adds or updates a project membership.
     *
     * @param projectId project identity
     * @param userId    user identity
     * @param role      role to assign
     * @return the created or updated membership
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the user does not exist
     */
    public ProjectMembership execute(ProjectId projectId, UserId userId, ProjectRole role) {
        log.debug("Upserting member: project={}, user={}, role={}", projectId.value, userId.value, role);
        callerAccess.resolve(projectId).ensure(Permission.MANAGE_MEMBERS);
        projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value))
                .ensureNotArchived();
        AppUser user = users.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User", userId.value));
        Optional<ProjectMembership> existing = memberships.findByProjectAndUser(projectId, userId);
        ProjectMembership membership = existing.map(m -> {
            log.debug("Updating existing member role: project={}, user={}, oldRole={}", projectId.value, userId.value, m.currentRole());
            m.changeRole(role);
            return m;
        }).orElseGet(() -> new ProjectMembership(projectId, userId, role));
        memberships.save(membership);
        membership.enrichWithUserInfo(user.email.value(), user.displayName().orElse(null));
        return membership;
    }
}
