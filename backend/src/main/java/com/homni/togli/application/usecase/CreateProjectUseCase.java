/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.EnvironmentRepositoryPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.exception.DomainValidationException;
import com.homni.togli.domain.model.Environment;
import com.homni.togli.domain.model.EnvironmentDefaults;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectSlug;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Creates a new project and bootstraps a chosen subset of the platform-wide
 * default environments inside it. All resolution and validation lives in the
 * {@link EnvironmentDefaults} domain object — this use case just orchestrates.
 */
public final class CreateProjectUseCase {

    private static final Logger log = LoggerFactory.getLogger(CreateProjectUseCase.class);

    private final ProjectRepositoryPort projects;
    private final EnvironmentRepositoryPort environments;
    private final EnvironmentDefaults environmentDefaults;

    /**
     * @param projects             project persistence port
     * @param environments         environment persistence port
     * @param environmentDefaults  platform-wide default environments policy
     */
    public CreateProjectUseCase(ProjectRepositoryPort projects,
                                 EnvironmentRepositoryPort environments,
                                 EnvironmentDefaults environmentDefaults) {
        this.projects = projects;
        this.environments = environments;
        this.environmentDefaults = environmentDefaults;
    }

    /**
     * Creates a project, persists it, then materializes the selected default
     * environments. See {@link EnvironmentDefaults#bootstrapFor} for the
     * semantics of {@code selectedEnvironmentNames}.
     *
     * @param slug                     unique project slug
     * @param name                     human-readable project name
     * @param description              optional project description
     * @param selectedEnvironmentNames subset of platform defaults to bootstrap, or {@code null} for all
     * @return the created project
     * @throws DomainValidationException if slug, name, or any selected env name is invalid
     */
    public Project execute(ProjectSlug slug, String name, String description,
                           List<String> selectedEnvironmentNames) {
        log.debug("Creating project: slug={}", slug.value());
        Project project = new Project(slug, name, description);
        projects.save(project);

        List<Environment> envs = environmentDefaults.bootstrapFor(project.id, selectedEnvironmentNames);
        if (!envs.isEmpty()) {
            environments.saveAll(envs);
        }
        log.debug("Project created: id={}, environments bootstrapped={}", project.id.value, envs.size());
        return project;
    }
}
