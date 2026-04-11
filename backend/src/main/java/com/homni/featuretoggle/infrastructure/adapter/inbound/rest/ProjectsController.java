/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.inbound.rest;

import com.homni.featuretoggle.application.usecase.CreateProjectUseCase;
import com.homni.featuretoggle.application.usecase.GetProjectBySlugUseCase;
import com.homni.featuretoggle.application.usecase.ListProjectsUseCase;
import com.homni.featuretoggle.application.usecase.ProjectPage;
import com.homni.featuretoggle.application.usecase.UpdateProjectUseCase;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.ProjectSlug;
import com.homni.featuretoggle.infrastructure.adapter.inbound.rest.presenter.ProjectPresenter;
import com.homni.generated.api.ProjectsApi;
import com.homni.generated.model.CreateProjectRequest;
import com.homni.generated.model.ProjectListResponse;
import com.homni.generated.model.ProjectSingleResponse;
import com.homni.generated.model.UpdateProjectRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Handles project CRUD operations.
 */
@RestController
class ProjectsController implements ProjectsApi {

    private final CreateProjectUseCase createProject;
    private final GetProjectBySlugUseCase getProjectBySlug;
    private final ListProjectsUseCase listProjects;
    private final UpdateProjectUseCase updateProject;
    private final ProjectPresenter presenter;

    /**
     * Creates the projects controller.
     *
     * @param createProject    the use case for project creation
     * @param getProjectBySlug the use case for fetching a project by slug
     * @param listProjects     the use case for listing projects
     * @param updateProject    the use case for updating a project
     * @param presenter        maps domain objects to API response models
     */
    ProjectsController(CreateProjectUseCase createProject,
                       GetProjectBySlugUseCase getProjectBySlug,
                       ListProjectsUseCase listProjects,
                       UpdateProjectUseCase updateProject,
                       ProjectPresenter presenter) {
        this.createProject = createProject;
        this.getProjectBySlug = getProjectBySlug;
        this.listProjects = listProjects;
        this.updateProject = updateProject;
        this.presenter = presenter;
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<ProjectSingleResponse> createProject(CreateProjectRequest req) {
        Project project = createProject.execute(
                new ProjectSlug(req.getSlug()),
                req.getName(),
                req.getDescription(),
                req.getEnvironments());
        return ResponseEntity.ok(presenter.single(project));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<ProjectSingleResponse> getProjectBySlug(String slug) {
        Project project = getProjectBySlug.execute(new ProjectSlug(slug));
        return ResponseEntity.ok(presenter.single(project));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<ProjectListResponse> listProjects(String q, Boolean archived,
                                                            Integer page, Integer size) {
        PaginationParams p = PaginationParams.of(page, size);
        ProjectPage result = listProjects.execute(q, archived, p.page(), p.size());
        return ResponseEntity.ok(presenter.list(result, p.page(), p.size()));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<ProjectSingleResponse> updateProject(UUID projectId,
                                                               UpdateProjectRequest req) {
        Project project = updateProject.execute(
                new ProjectId(projectId), req.getName(), req.getDescription(), req.getArchived());
        return ResponseEntity.ok(presenter.single(project));
    }
}
