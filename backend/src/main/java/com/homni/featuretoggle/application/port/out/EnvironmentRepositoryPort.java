/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.port.out;

import com.homni.featuretoggle.domain.model.Environment;
import com.homni.featuretoggle.domain.model.EnvironmentId;
import com.homni.featuretoggle.domain.model.ProjectId;

import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * Output port for persisting deployment environments scoped to a project.
 */
public interface EnvironmentRepositoryPort {

    /**
     * Saves an environment (insert or update).
     *
     * @param environment the environment to save
     */
    void save(Environment environment);

    /**
     * Finds an environment by identity.
     *
     * @param id environment identity
     * @return the environment if found, or empty
     */
    Optional<Environment> findById(EnvironmentId id);

    /**
     * Lists all environments for a project, ordered by name.
     *
     * @param projectId owning project identity
     * @return the project's environments
     */
    List<Environment> findAllByProject(ProjectId projectId);

    /**
     * Returns environment names defined in a project.
     *
     * @param projectId owning project identity
     * @return environment names
     */
    Set<String> findNamesByProjectId(ProjectId projectId);

    /**
     * Deletes an environment by identity.
     *
     * @param id environment identity
     */
    void deleteById(EnvironmentId id);

    /**
     * Checks if any toggle references this environment.
     *
     * @param name      environment name to check
     * @param projectId owning project identity
     * @return {@code true} if at least one toggle uses it
     */
    boolean isEnvironmentInUse(String name, ProjectId projectId);
}
