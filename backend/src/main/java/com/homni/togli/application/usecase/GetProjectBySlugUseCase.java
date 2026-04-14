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
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectSlug;

/**
 * Retrieves a single project by slug with access control.
 *
 * <p>Returns 404 if the slug does not exist, 403 if the caller
 * is not a member (unless they are a platform admin).
 */
public final class GetProjectBySlugUseCase {

    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    public GetProjectBySlugUseCase(ProjectRepositoryPort projects,
                                   CallerProjectAccessPort callerAccess) {
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Finds the project by slug and verifies the caller has access.
     *
     * @param slug the project slug
     * @return the project
     * @throws EntityNotFoundException if no project with this slug exists
     * @throws com.homni.togli.domain.exception.NotProjectMemberException
     *         if the caller is not a member of the project
     */
    public Project execute(ProjectSlug slug) {
        Project project = projects.findBySlug(slug)
                .orElseThrow(() -> new EntityNotFoundException("Project", slug.value()));

        callerAccess.resolve(project.id);

        return project;
    }
}
