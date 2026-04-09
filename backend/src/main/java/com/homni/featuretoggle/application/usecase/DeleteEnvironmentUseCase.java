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
import com.homni.featuretoggle.domain.exception.EnvironmentInUseException;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.exception.ProjectArchivedException;
import com.homni.featuretoggle.domain.model.Environment;
import com.homni.featuretoggle.domain.model.EnvironmentId;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.ProjectId;

/**
 * Deletes a deployment environment from a project.
 */
public final class DeleteEnvironmentUseCase {

    private final EnvironmentRepositoryPort environments;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param environments environment persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public DeleteEnvironmentUseCase(EnvironmentRepositoryPort environments,
                                    ProjectRepositoryPort projects,
                                    CallerProjectAccessPort callerAccess) {
        this.environments = environments;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Deletes an environment from a project.
     *
     * @param id        environment identity
     * @param projectId owning project identity
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks WRITE_TOGGLES
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the environment does not exist
     * @throws EnvironmentInUseException if referenced by toggles
     */
    public void execute(EnvironmentId id, ProjectId projectId) {
        callerAccess.resolve(projectId).ensure(Permission.WRITE_TOGGLES);
        projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value))
                .ensureNotArchived();
        Environment environment = environments.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Environment", id.value));
        if (environments.isEnvironmentInUse(environment.name(), projectId)) {
            throw new EnvironmentInUseException(environment.name());
        }
        environments.deleteById(id);
    }
}
