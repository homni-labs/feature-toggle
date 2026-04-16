/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.integration;

import com.homni.togli.application.port.out.FeatureToggleRepositoryPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.CreateToggleUseCase;
import com.homni.togli.application.usecase.UpdateProjectUseCase;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.Project;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for {@link UpdateProjectUseCase}.
 */
@DisplayName("UpdateProject (integration)")
class UpdateProjectIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired UpdateProjectUseCase updateProject;
    @Autowired CreateToggleUseCase createToggle;
    @Autowired ProjectRepositoryPort projects;
    @Autowired FeatureToggleRepositoryPort toggles;

    AppUser admin;
    Project project;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
        project = createProject.execute(randomSlug(), "Original " + randomSuffix(), null, null);
    }

    @Test
    @DisplayName("renames project in database")
    void renamesProject() {
        String newName = "Renamed " + randomSuffix();

        Project updated = updateProject.execute(project.id, newName, null, null);

        assertThat(updated.name()).isEqualTo(newName);
        Project fromDb = projects.findById(project.id).orElseThrow();
        assertThat(fromDb.name()).isEqualTo(newName);
    }

    @Test
    @DisplayName("archiving disables all enabled toggles in database")
    void archivingDisablesToggles() {
        FeatureToggle toggle = createToggle.execute(
                project.id, "toggle-" + randomSuffix(), null, Set.of("DEV", "PROD"));
        toggle.setEnvironmentStates(Map.of("DEV", true, "PROD", true));
        toggles.save(toggle);

        updateProject.execute(project.id, null, null, true);

        FeatureToggle fromDb = toggles.findById(toggle.id).orElseThrow();
        assertThat(fromDb.isEnabledIn("DEV")).isFalse();
        assertThat(fromDb.isEnabledIn("PROD")).isFalse();
    }

    @Test
    @DisplayName("unarchives a previously archived project")
    void unarchivesProject() {
        updateProject.execute(project.id, null, null, true);

        Project unarchived = updateProject.execute(project.id, null, null, false);

        assertThat(unarchived.isArchived()).isFalse();
    }
}
