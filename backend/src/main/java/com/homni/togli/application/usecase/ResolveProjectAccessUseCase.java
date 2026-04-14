/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.ProjectAccess;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectMembership;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Optional;

/**
 * Resolves the caller's access level for a project.
 */
public final class ResolveProjectAccessUseCase {

    private static final Logger log = LoggerFactory.getLogger(ResolveProjectAccessUseCase.class);

    private final ProjectMembershipRepositoryPort memberships;

    /**
     * @param memberships membership persistence port
     */
    public ResolveProjectAccessUseCase(ProjectMembershipRepositoryPort memberships) {
        this.memberships = memberships;
    }

    /**
     * Resolves project access for a user.
     *
     * @param caller    authenticated user
     * @param projectId target project identity
     * @return the resolved access level
     * @throws com.homni.togli.domain.exception.NotProjectMemberException if the user has no access
     */
    public ProjectAccess resolve(AppUser caller, ProjectId projectId) {
        log.debug("Resolving access: user={}, project={}", caller.id.value, projectId.value);
        Optional<ProjectMembership> membership = memberships.findByProjectAndUser(
                projectId, caller.id);
        ProjectAccess access = caller.accessFor(projectId, membership);
        log.debug("Access resolved: user={}, project={}, access={}", caller.id.value, projectId.value, access);
        return access;
    }
}
