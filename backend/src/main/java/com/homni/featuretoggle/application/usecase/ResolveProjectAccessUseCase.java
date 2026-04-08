/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.featuretoggle.domain.model.AppUser;
import com.homni.featuretoggle.domain.model.ProjectAccess;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.ProjectMembership;

import java.util.Optional;

/**
 * Resolves the caller's access level for a project.
 */
public final class ResolveProjectAccessUseCase {

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
     * @throws com.homni.featuretoggle.domain.exception.NotProjectMemberException if the user has no access
     */
    public ProjectAccess resolve(AppUser caller, ProjectId projectId) {
        Optional<ProjectMembership> membership = memberships.findByProjectAndUser(
                projectId, caller.id);
        return caller.accessFor(projectId, membership);
    }
}
