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

import java.util.Map;
import java.util.Set;

/**
 * Updates a feature toggle's mutable fields and per-environment enabled state.
 * Pure orchestration: load aggregates, delegate every business rule to the
 * domain, then persist.
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
     * Updates a feature toggle. The {@code environmentStateChanges} map flips
     * the enabled flag per env independently — see
     * {@link FeatureToggle#setEnvironmentStates}.
     *
     * @param id                       toggle identity
     * @param name                     new name, or {@code null} to keep
     * @param description              new description, or {@code null} to keep
     * @param environmentNames         new environment set, or {@code null} to keep
     * @param environmentStateChanges  per-env enabled changes, or {@code null} to skip
     * @return the updated feature toggle
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks WRITE_TOGGLES
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the toggle or its project does not exist
     */
    public FeatureToggle execute(FeatureToggleId id, String name, String description,
                                 Set<String> environmentNames,
                                 Map<String, Boolean> environmentStateChanges) {
        FeatureToggle toggle = toggles.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Toggle", id.value));
        callerAccess.resolve(toggle.projectId).ensure(Permission.WRITE_TOGGLES);

        Project project = projects.findById(toggle.projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", toggle.projectId.value));
        project.ensureNotArchived();

        Set<String> projectEnvs = environments.findNamesByProjectId(toggle.projectId);
        toggle.update(name, description, environmentNames, projectEnvs);
        toggle.setEnvironmentStates(environmentStateChanges);

        toggles.save(toggle);
        return toggle;
    }
}
