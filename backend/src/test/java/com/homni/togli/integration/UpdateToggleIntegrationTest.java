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
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.CreateToggleUseCase;
import com.homni.togli.application.usecase.UpdateToggleUseCase;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.FeatureToggleId;
import com.homni.togli.domain.model.Project;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for {@link UpdateToggleUseCase}.
 */
@DisplayName("UpdateToggle (integration)")
class UpdateToggleIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired CreateToggleUseCase createToggle;
    @Autowired UpdateToggleUseCase updateToggle;
    @Autowired FeatureToggleRepositoryPort toggles;

    AppUser admin;
    Project project;
    FeatureToggle toggle;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
        project = createProject.execute(randomSlug(), "Project " + randomSuffix(), null, null);
        toggle = createToggle.execute(project.id, "toggle-" + randomSuffix(), null, Set.of("DEV", "PROD"));
    }

    @Test
    @DisplayName("enables environment and persists state in database")
    void enablesEnvironment() {
        FeatureToggle updated = updateToggle.execute(
                toggle.id, null, null, null, Map.of("DEV", true));

        assertThat(updated.isEnabledIn("DEV")).isTrue();
        assertThat(updated.isEnabledIn("PROD")).isFalse();

        FeatureToggle fromDb = toggles.findById(toggle.id).orElseThrow();
        assertThat(fromDb.isEnabledIn("DEV")).isTrue();
    }

    @Test
    @DisplayName("renames toggle in database")
    void renamesToggles() {
        String newName = "renamed-" + randomSuffix();

        FeatureToggle updated = updateToggle.execute(
                toggle.id, newName, null, null, null);

        assertThat(updated.name()).isEqualTo(newName);
        FeatureToggle fromDb = toggles.findById(toggle.id).orElseThrow();
        assertThat(fromDb.name()).isEqualTo(newName);
    }

    @Test
    @DisplayName("adds environment starting as disabled and preserves existing state")
    void addsEnvironment() {
        updateToggle.execute(toggle.id, null, null, null, Map.of("DEV", true));

        FeatureToggle updated = updateToggle.execute(
                toggle.id, null, null, Set.of("DEV", "PROD", "TEST"), null);

        assertThat(updated.environments()).containsExactlyInAnyOrder("DEV", "PROD", "TEST");
        assertThat(updated.isEnabledIn("DEV")).isTrue();
        assertThat(updated.isEnabledIn("TEST")).isFalse();
    }

    @Test
    @DisplayName("removes environment and drops its state from database")
    void removesEnvironment() {
        updateToggle.execute(toggle.id, null, null, null, Map.of("DEV", true, "PROD", true));

        FeatureToggle updated = updateToggle.execute(
                toggle.id, null, null, Set.of("DEV"), null);

        assertThat(updated.environments()).containsExactly("DEV");
        assertThat(updated.isEnabledIn("DEV")).isTrue();

        FeatureToggle fromDb = toggles.findById(toggle.id).orElseThrow();
        assertThat(fromDb.environments()).containsExactly("DEV");
    }
}
