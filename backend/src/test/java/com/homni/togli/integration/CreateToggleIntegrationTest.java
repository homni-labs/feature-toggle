/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.integration;

import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.CreateToggleUseCase;
import com.homni.togli.application.usecase.UpdateProjectUseCase;
import com.homni.togli.domain.exception.DomainValidationException;
import com.homni.togli.domain.exception.InsufficientPermissionException;
import com.homni.togli.domain.exception.ProjectArchivedException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Integration tests for {@link CreateToggleUseCase}.
 */
@DisplayName("CreateToggle (integration)")
class CreateToggleIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired CreateToggleUseCase createToggle;
    @Autowired UpdateProjectUseCase updateProject;

    AppUser admin;
    Project project;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
        project = createProject.execute(randomSlug(), "Project " + randomSuffix(), null, null);
    }

    @Test
    @DisplayName("creates toggle with environments persisted in database")
    void createsToggle() {
        FeatureToggle toggle = createToggle.execute(
                project.id, "dark-mode-" + randomSuffix(), "Dark theme", Set.of("DEV", "PROD"));

        assertThat(toggle.id).isNotNull();
        assertThat(toggle.environments()).containsExactlyInAnyOrder("DEV", "PROD");
        assertThat(toggle.isEnabledIn("DEV")).isFalse();
    }

    @Test
    @DisplayName("rejects creation on archived project")
    void rejectsArchivedProject() {
        updateProject.execute(project.id, null, null, true);

        assertThatThrownBy(() -> createToggle.execute(
                project.id, "toggle-" + randomSuffix(), null, Set.of("DEV")))
                .isInstanceOf(ProjectArchivedException.class);
    }

    @Test
    @DisplayName("rejects environment not present in project")
    void rejectsAlienEnvironment() {
        assertThatThrownBy(() -> createToggle.execute(
                project.id, "toggle-" + randomSuffix(), null, Set.of("STAGING")))
                .isInstanceOf(DomainValidationException.class)
                .hasMessageContaining("STAGING");
    }

    @Test
    @DisplayName("rejects creation when caller has only READER role")
    void rejectsInsufficientPermission() {
        AppUser reader = regularUser();
        actAsMember(reader, project.id, ProjectRole.READER);

        assertThatThrownBy(() -> createToggle.execute(
                project.id, "toggle-" + randomSuffix(), null, Set.of("DEV")))
                .isInstanceOf(InsufficientPermissionException.class);
    }
}
