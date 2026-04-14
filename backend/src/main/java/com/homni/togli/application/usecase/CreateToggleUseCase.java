/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.application.port.out.EnvironmentRepositoryPort;
import com.homni.togli.application.port.out.FeatureToggleRepositoryPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.ProjectArchivedException;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Set;

/**
 * Creates a feature toggle in a project. Pure orchestration: load aggregates,
 * delegate every business rule to the domain, then persist.
 */
public final class CreateToggleUseCase {

    private static final Logger log = LoggerFactory.getLogger(CreateToggleUseCase.class);

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
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks WRITE_TOGGLES
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the project does not exist
     */
    public FeatureToggle execute(ProjectId projectId, String name, String description,
                                 Set<String> environmentNames) {
        log.debug("Creating toggle: project={}, name={}", projectId.value, name);
        callerAccess.resolve(projectId).ensure(Permission.WRITE_TOGGLES);

        Project project = projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value));
        project.ensureNotArchived();

        Set<String> projectEnvs = environments.findNamesByProjectId(projectId);
        FeatureToggle toggle = new FeatureToggle(projectId, name, description, environmentNames, projectEnvs);
        toggles.save(toggle);
        log.debug("Toggle created: id={}, environments={}", toggle.id.value, environmentNames);
        return toggle;
    }
}
