/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.port.out;

import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.application.usecase.ProjectWithRole;
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
     * Returns all projects ordered by name.
     *
     * @return all projects
     */
    List<Project> findAll();

    /**
     * Returns projects where the user is a member.
     *
     * @param userId user identity
     * @return the user's projects
     */
    List<Project> findByMember(UserId userId);

    /**
     * Returns non-archived projects with the user's role.
     *
     * @param userId user identity
     * @return projects with role
     */
    List<ProjectWithRole> findByMemberWithRole(UserId userId);
}
