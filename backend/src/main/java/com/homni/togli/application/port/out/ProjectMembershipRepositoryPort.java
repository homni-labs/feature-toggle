/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.port.out;

import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.togli.domain.model.UserId;

import java.util.List;
import java.util.Optional;

/**
 * Output port for persisting project memberships.
 */
public interface ProjectMembershipRepositoryPort {

    /**
     * Saves a membership (insert or update).
     *
     * @param membership the membership to save
     */
    void save(ProjectMembership membership);

    /**
     * Finds a membership by project and user.
     *
     * @param projectId project identity
     * @param userId    user identity
     * @return the membership if found, or empty
     */
    Optional<ProjectMembership> findByProjectAndUser(ProjectId projectId, UserId userId);

    /**
     * Lists memberships for a project with pagination.
     *
     * @param projectId project identity
     * @param offset    rows to skip
     * @param limit     max rows to return
     * @return the project's memberships
     */
    List<ProjectMembership> findByProject(ProjectId projectId, int offset, int limit);

    /**
     * Counts memberships in a project.
     *
     * @param projectId project identity
     * @return the member count
     */
    long countByProject(ProjectId projectId);

    /**
     * Removes a membership by project and user.
     *
     * @param projectId project identity
     * @param userId    user identity
     */
    void deleteByProjectAndUser(ProjectId projectId, UserId userId);
}
