/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectSlug;

/**
 * Creates a new project.
 */
public final class CreateProjectUseCase {

    private final ProjectRepositoryPort projects;

    /**
     * @param projects project persistence port
     */
    public CreateProjectUseCase(ProjectRepositoryPort projects) {
        this.projects = projects;
    }

    /**
     * Creates a project and persists it.
     *
     * @param slug        unique project slug
     * @param name        human-readable project name
     * @param description optional project description
     * @return the created project
     * @throws com.homni.featuretoggle.domain.exception.DomainValidationException if slug or name is invalid
     */
    public Project execute(ProjectSlug slug, String name, String description) {
        Project project = new Project(slug, name, description);
        projects.save(project);
        return project;
    }
}
