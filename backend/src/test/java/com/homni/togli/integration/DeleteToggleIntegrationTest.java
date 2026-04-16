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
import com.homni.togli.application.usecase.DeleteToggleUseCase;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.InsufficientPermissionException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.FeatureToggleId;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Integration tests for {@link DeleteToggleUseCase}.
 */
@DisplayName("DeleteToggle (integration)")
class DeleteToggleIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired CreateToggleUseCase createToggle;
    @Autowired DeleteToggleUseCase deleteToggle;
    @Autowired FeatureToggleRepositoryPort toggles;

    AppUser admin;
    Project project;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
        project = createProject.execute(randomSlug(), "Project " + randomSuffix(), null, null);
    }

    @Test
    @DisplayName("deletes toggle from database")
    void deletesToggle() {
        FeatureToggle toggle = createToggle.execute(
                project.id, "toggle-" + randomSuffix(), null, Set.of("DEV"));

        deleteToggle.execute(toggle.id);

        assertThat(toggles.findById(toggle.id)).isEmpty();
    }

    @Test
    @DisplayName("rejects deletion of non-existent toggle")
    void rejectsNonExistent() {
        FeatureToggleId fakeId = new FeatureToggleId(UUID.randomUUID());

        assertThatThrownBy(() -> deleteToggle.execute(fakeId))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    @DisplayName("rejects deletion when caller has only READER role")
    void rejectsInsufficientPermission() {
        FeatureToggle toggle = createToggle.execute(
                project.id, "toggle-" + randomSuffix(), null, Set.of("DEV"));

        AppUser reader = regularUser();
        actAsMember(reader, project.id, ProjectRole.READER);

        assertThatThrownBy(() -> deleteToggle.execute(toggle.id))
                .isInstanceOf(InsufficientPermissionException.class);
    }
}
