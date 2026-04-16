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
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.Environment;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectSlug;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Integration tests for {@link CreateProjectUseCase}.
 *
 * <p>Verifies the full chain: use case → repository port → JDBC adapter → PostgreSQL.
 */
@DisplayName("CreateProject (integration)")
class CreateProjectIntegrationTest extends BaseIntegrationTest {

    @Autowired
    CreateProjectUseCase createProject;

    @Autowired
    ProjectRepositoryPort projects;

    @Autowired
    EnvironmentRepositoryPort environments;

    AppUser admin;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
    }

    @Test
    @DisplayName("creates project with default environments persisted in database")
    void createsProjectWithDefaultEnvironments() {
        ProjectSlug slug = randomSlug();

        Project project = createProject.execute(slug, "My Project", "A description", null);

        assertThat(projects.findById(project.id)).isPresent();
        List<Environment> envs = environments.findAllByProject(project.id);
        assertThat(envs).extracting(Environment::name)
                .containsExactlyInAnyOrder("DEV", "TEST", "PROD");
    }

    @Test
    @DisplayName("creates project with custom environment subset")
    void createsProjectWithCustomEnvironments() {
        ProjectSlug slug = randomSlug();

        Project project = createProject.execute(slug, "Custom Envs", null, List.of("DEV"));

        List<Environment> envs = environments.findAllByProject(project.id);
        assertThat(envs).hasSize(1);
        assertThat(envs.getFirst().name()).isEqualTo("DEV");
    }

    @Test
    @DisplayName("rejects duplicate project slug")
    void rejectsDuplicateSlug() {
        ProjectSlug slug = randomSlug();
        createProject.execute(slug, "First", null, null);

        assertThatThrownBy(() -> createProject.execute(slug, "Second", null, null))
                .isInstanceOf(AlreadyExistsException.class);
    }

}
