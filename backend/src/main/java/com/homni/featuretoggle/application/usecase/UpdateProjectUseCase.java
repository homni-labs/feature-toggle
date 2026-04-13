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
import com.homni.featuretoggle.domain.exception.InvalidStateException;
import com.homni.featuretoggle.domain.exception.ProjectArchivedException;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Updates mutable fields of an existing project.
 */
public final class UpdateProjectUseCase {

    private static final Logger log = LoggerFactory.getLogger(UpdateProjectUseCase.class);

    private final ProjectRepositoryPort projects;
    private final FeatureToggleRepositoryPort toggles;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param projects     project persistence port
     * @param toggles      toggle persistence port (used to disable toggles on archive)
     * @param callerAccess caller's project access resolver
     */
    public UpdateProjectUseCase(ProjectRepositoryPort projects,
                                 FeatureToggleRepositoryPort toggles,
                                 CallerProjectAccessPort callerAccess) {
        this.projects = projects;
        this.toggles = toggles;
        this.callerAccess = callerAccess;
    }

    /**
     * Updates a project's name, description, and/or archived status.
     * <p>
     * If the project is currently archived, the only permitted change is
     * unarchiving (setting {@code archived=false}). Any attempt to change name,
     * description, or to re-archive an already archived project will be rejected
     * with {@link ProjectArchivedException}.
     * <p>
     * When transitioning a project from active to archived, every enabled
     * feature toggle in the project is bulk-disabled before the project is
     * persisted, so an archived project never has any toggles switched on.
     *
     * @param id          project identity
     * @param name        new project name
     * @param description new description, may be {@code null}
     * @param archived    new archived flag, or {@code null} to keep
     * @return the updated project
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     * @throws EntityNotFoundException if the project does not exist
     * @throws ProjectArchivedException if the project is archived and the request asks for anything other than unarchive
     * @throws com.homni.featuretoggle.domain.exception.DomainValidationException if name is invalid
     * @throws InvalidStateException if archive/unarchive transition is invalid
     */
    public Project execute(ProjectId id, String name, String description, Boolean archived) {
        log.debug("Updating project: id={}, archived={}", id.value, archived);
        callerAccess.resolve(id).ensure(Permission.MANAGE_MEMBERS);
        Project project = projects.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Project", id.value));

        if (project.isArchived() && !isUnarchiveOnlyRequest(name, description, archived)) {
            throw new ProjectArchivedException(id);
        }

        boolean willArchive = Boolean.TRUE.equals(archived) && !project.isArchived();
        if (willArchive) {
            int disabled = toggles.disableAllByProject(id);
            log.debug("Archiving project {}: disabled {} toggle-environment pairs", id.value, disabled);
        }

        project.update(name, description);
        applyArchivedChange(project, archived);
        projects.save(project);
        log.debug("Project updated: id={}", project.id.value);
        return project;
    }

    private boolean isUnarchiveOnlyRequest(String name, String description, Boolean archived) {
        return name == null && description == null && Boolean.FALSE.equals(archived);
    }

    private void applyArchivedChange(Project project, Boolean archived) {
        if (archived == null || archived == project.isArchived()) {
            return;
        }
        if (archived) {
            project.archive();
        } else {
            project.unarchive();
        }
    }
}
