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
import com.homni.featuretoggle.application.port.out.FeatureToggleRepositoryPort;
import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.exception.ProjectArchivedException;
import com.homni.featuretoggle.domain.model.FeatureToggle;
import com.homni.featuretoggle.domain.model.FeatureToggleId;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;

/**
 * Deletes a feature toggle from a project.
 */
public final class DeleteToggleUseCase {

    private final FeatureToggleRepositoryPort toggles;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param toggles      toggle persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public DeleteToggleUseCase(FeatureToggleRepositoryPort toggles,
                               ProjectRepositoryPort projects,
                               CallerProjectAccessPort callerAccess) {
        this.toggles = toggles;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Deletes a feature toggle.
     *
     * @param id toggle identity
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks WRITE_TOGGLES
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the toggle does not exist
     */
    public void execute(FeatureToggleId id) {
        FeatureToggle toggle = toggles.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Toggle", id.value));
        callerAccess.resolve(toggle.projectId).ensure(Permission.WRITE_TOGGLES);
        ensureProjectNotArchived(toggle.projectId);
        toggles.deleteById(id);
    }

    private void ensureProjectNotArchived(ProjectId projectId) {
        Project project = projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value));
        if (project.isArchived()) {
            throw new ProjectArchivedException(projectId);
        }
    }
}
