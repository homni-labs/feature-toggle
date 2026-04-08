/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.CallerProjectAccessPort;
import com.homni.featuretoggle.application.port.out.EnvironmentRepositoryPort;
import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.exception.ProjectArchivedException;
import com.homni.featuretoggle.domain.model.Environment;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;

/**
 * Creates a deployment environment in a project.
 */
public final class CreateEnvironmentUseCase {

    private final EnvironmentRepositoryPort environments;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param environments environment persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public CreateEnvironmentUseCase(EnvironmentRepositoryPort environments,
                                    ProjectRepositoryPort projects,
                                    CallerProjectAccessPort callerAccess) {
        this.environments = environments;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Creates an environment in a project.
     *
     * @param projectId owning project identity
     * @param name      environment name (uppercased)
     * @return the created environment
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks WRITE_TOGGLES
     * @throws ProjectArchivedException if the project is archived
     * @throws com.homni.featuretoggle.domain.exception.DomainValidationException if the name is invalid
     */
    public Environment execute(ProjectId projectId, String name) {
        callerAccess.resolve(projectId).ensure(Permission.WRITE_TOGGLES);
        ensureProjectNotArchived(projectId);
        Environment environment = new Environment(projectId, name);
        environments.save(environment);
        return environment;
    }

    private void ensureProjectNotArchived(ProjectId projectId) {
        Project project = projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value));
        if (project.isArchived()) {
            throw new ProjectArchivedException(projectId);
        }
    }
}
