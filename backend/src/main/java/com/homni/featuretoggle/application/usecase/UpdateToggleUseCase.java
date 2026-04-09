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
import com.homni.featuretoggle.domain.model.FeatureToggleId;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;

import java.util.Set;

/**
 * Updates a feature toggle's mutable fields.
 */
public final class UpdateToggleUseCase {

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
    public UpdateToggleUseCase(FeatureToggleRepositoryPort toggles,
                               EnvironmentRepositoryPort environments,
                               ProjectRepositoryPort projects,
                               CallerProjectAccessPort callerAccess) {
        this.toggles = toggles;
        this.environments = environments;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Updates a feature toggle including enable/disable.
     *
     * @param id               toggle identity
     * @param name             new name, or {@code null} to keep
     * @param description      new description, or {@code null} to keep
     * @param environmentNames new environments, or {@code null} to keep
     * @param enabled          new enabled flag, or {@code null} to keep
     * @return the updated feature toggle
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks WRITE_TOGGLES
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if toggle or environment does not exist
     */
    public FeatureToggle execute(FeatureToggleId id, String name, String description,
                                 Set<String> environmentNames, Boolean enabled) {
        FeatureToggle toggle = toggles.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Toggle", id.value));
        callerAccess.resolve(toggle.projectId).ensure(Permission.WRITE_TOGGLES);
        ensureProjectNotArchived(toggle.projectId);
        if (environmentNames != null && !environmentNames.isEmpty()) {
            validateEnvironmentsExist(toggle.projectId, environmentNames);
        }
        toggle.update(name, description, environmentNames);
        applyEnabledChange(toggle, enabled);
        toggles.save(toggle);
        return toggle;
    }

    private void applyEnabledChange(FeatureToggle toggle, Boolean enabled) {
        if (Boolean.TRUE.equals(enabled) && !toggle.isEnabled()) {
            toggle.enable();
        } else if (Boolean.FALSE.equals(enabled) && toggle.isEnabled()) {
            toggle.disable();
        }
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
        for (String envName : requested) {
            if (!existing.contains(envName)) {
                throw new EntityNotFoundException("Environment", envName + " in project " + projectId.value);
            }
        }
    }
}
