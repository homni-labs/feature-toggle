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
import com.homni.featuretoggle.application.port.out.FeatureToggleRepositoryPort;
import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.exception.ProjectArchivedException;
import com.homni.featuretoggle.domain.model.FeatureToggle;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;

import java.util.Set;

/**
 * Creates a feature toggle in a project.
 */
public final class CreateToggleUseCase {

    private final FeatureToggleRepositoryPort toggles;
    private final EnvironmentRepositoryPort environments;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param toggles      toggle persistence port
     * @param environments environment persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public CreateToggleUseCase(FeatureToggleRepositoryPort toggles,
                               EnvironmentRepositoryPort environments,
                               ProjectRepositoryPort projects,
                               CallerProjectAccessPort callerAccess) {
        this.toggles = toggles;
        this.environments = environments;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Creates a feature toggle in a project.
     *
     * @param projectId        owning project identity
     * @param name             toggle name
     * @param description      optional toggle description
     * @param environmentNames environment names to assign
     * @return the created feature toggle
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks WRITE_TOGGLES
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if any environment does not exist
     */
    public FeatureToggle execute(ProjectId projectId, String name, String description,
                                 Set<String> environmentNames) {
        callerAccess.resolve(projectId).ensure(Permission.WRITE_TOGGLES);
        ensureProjectNotArchived(projectId);
        validateEnvironmentsExist(projectId, environmentNames);
        FeatureToggle toggle = new FeatureToggle(projectId, name, description, environmentNames);
        toggles.save(toggle);
        return toggle;
    }

    private void ensureProjectNotArchived(ProjectId projectId) {
        Project project = projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value));
        if (project.isArchived()) {
            throw new ProjectArchivedException(projectId);
        }
    }

    private void validateEnvironmentsExist(ProjectId projectId, Set<String> requested) {
        Set<String> existing = environments.findNamesByProjectId(projectId);
        for (String name : requested) {
            if (!existing.contains(name)) {
                throw new EntityNotFoundException("Environment", name + " in project " + projectId.value);
            }
        }
    }
}
