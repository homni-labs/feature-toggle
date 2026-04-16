/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.integration;

import com.homni.togli.application.port.out.EnvironmentRepositoryPort;
import com.homni.togli.application.usecase.CreateEnvironmentUseCase;
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.CreateToggleUseCase;
import com.homni.togli.application.usecase.DeleteEnvironmentUseCase;
import com.homni.togli.domain.exception.EnvironmentInUseException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.Environment;
import com.homni.togli.domain.model.Project;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Integration tests for {@link DeleteEnvironmentUseCase}.
 */
@DisplayName("DeleteEnvironment (integration)")
class DeleteEnvironmentIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired CreateEnvironmentUseCase createEnvironment;
    @Autowired CreateToggleUseCase createToggle;
    @Autowired DeleteEnvironmentUseCase deleteEnvironment;
    @Autowired EnvironmentRepositoryPort environments;

    AppUser admin;
    Project project;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
        project = createProject.execute(randomSlug(), "Project " + randomSuffix(), null, null);
    }

    @Test
    @DisplayName("deletes unused environment from database")
    void deletesUnusedEnvironment() {
        Environment extra = createEnvironment.execute(project.id, "EXTRA_" + randomSuffix());

        deleteEnvironment.execute(extra.id, project.id);

        assertThat(environments.findById(extra.id)).isEmpty();
    }

    @Test
    @DisplayName("rejects deletion of environment used by a toggle")
    void rejectsInUseEnvironment() {
        List<Environment> envs = environments.findAllByProject(project.id);
        Environment dev = envs.stream().filter(e -> e.name().equals("DEV")).findFirst().orElseThrow();
        createToggle.execute(project.id, "toggle-" + randomSuffix(), null, Set.of("DEV"));

        assertThatThrownBy(() -> deleteEnvironment.execute(dev.id, project.id))
                .isInstanceOf(EnvironmentInUseException.class)
                .hasMessageContaining("DEV");
    }

    @Test
    @DisplayName("allows deletion after toggle no longer uses the environment")
    void allowsDeletionAfterToggleRemoved() {
        Environment extra = createEnvironment.execute(project.id, "STAGING_" + randomSuffix());
        // extra is not used by any toggle

        deleteEnvironment.execute(extra.id, project.id);

        assertThat(environments.findById(extra.id)).isEmpty();
    }
}
