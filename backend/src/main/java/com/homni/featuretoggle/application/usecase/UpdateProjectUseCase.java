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
import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.exception.InvalidStateException;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;

/**
 * Updates mutable fields of an existing project.
 */
public final class UpdateProjectUseCase {

    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public UpdateProjectUseCase(ProjectRepositoryPort projects,
                                 CallerProjectAccessPort callerAccess) {
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Updates a project's name, description, and/or archived status.
     *
     * @param id          project identity
     * @param name        new project name
     * @param description new description, may be {@code null}
     * @param archived    new archived flag, or {@code null} to keep
     * @return the updated project
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     * @throws EntityNotFoundException if the project does not exist
     * @throws com.homni.featuretoggle.domain.exception.DomainValidationException if name is invalid
     * @throws InvalidStateException if archive/unarchive transition is invalid
     */
    public Project execute(ProjectId id, String name, String description, Boolean archived) {
        callerAccess.resolve(id).ensure(Permission.MANAGE_MEMBERS);
        Project project = projects.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Project", id.value));
        project.update(name, description);
        applyArchivedChange(project, archived);
        projects.save(project);
        return project;
    }

    private void applyArchivedChange(Project project, Boolean archived) {
        if (Boolean.TRUE.equals(archived) && !project.isArchived()) {
            project.archive();
        } else if (Boolean.FALSE.equals(archived) && project.isArchived()) {
            project.unarchive();
        }
    }
}
