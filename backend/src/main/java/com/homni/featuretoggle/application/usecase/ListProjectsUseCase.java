/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.CallerPort;
import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.model.AppUser;

import java.util.List;

/**
 * Lists projects visible to the calling user.
 */
public final class ListProjectsUseCase {

    private final ProjectRepositoryPort projects;
    private final CallerPort callerPort;

    /**
     * @param projects   project persistence port
     * @param callerPort authenticated caller provider
     */
    public ListProjectsUseCase(ProjectRepositoryPort projects, CallerPort callerPort) {
        this.projects = projects;
        this.callerPort = callerPort;
    }

    /**
     * Lists projects accessible to the caller with their role.
     *
     * @return projects with the caller's role
     */
    public List<ProjectWithRole> execute() {
        AppUser caller = callerPort.get();
        if (caller.isPlatformAdmin()) {
            return projects.findAll().stream()
                    .map(project -> new ProjectWithRole(project, null))
                    .toList();
        }
        return projects.findByMemberWithRole(caller.id);
    }
}
