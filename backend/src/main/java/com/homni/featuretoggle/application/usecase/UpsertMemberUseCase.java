/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.AppUserRepositoryPort;
import com.homni.featuretoggle.application.port.out.CallerProjectAccessPort;
import com.homni.featuretoggle.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.exception.ProjectArchivedException;
import com.homni.featuretoggle.domain.model.AppUser;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.ProjectMembership;
import com.homni.featuretoggle.domain.model.ProjectRole;
import com.homni.featuretoggle.domain.model.UserId;

import java.util.Optional;

/**
 * Adds a user to a project or updates their role (upsert semantics).
 */
public final class UpsertMemberUseCase {

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
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the user does not exist
     */
    public ProjectMembership execute(ProjectId projectId, UserId userId, ProjectRole role) {
        callerAccess.resolve(projectId).ensure(Permission.MANAGE_MEMBERS);
        ensureProjectNotArchived(projectId);
        AppUser user = users.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User", userId.value));
        Optional<ProjectMembership> existing = memberships.findByProjectAndUser(projectId, userId);
        ProjectMembership membership = existing.map(m -> {
            m.changeRole(role);
            return m;
        }).orElseGet(() -> new ProjectMembership(projectId, userId, role));
        memberships.save(membership);
        membership.enrichWithUserInfo(user.email.value(), user.displayName().orElse(null));
        return membership;
    }

    private void ensureProjectNotArchived(ProjectId projectId) {
        Project project = projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value));
        if (project.isArchived()) {
            throw new ProjectArchivedException(projectId);
        }
    }
}
