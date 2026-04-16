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
import com.homni.togli.application.usecase.ListTogglesUseCase;
import com.homni.togli.application.usecase.TogglePage;
import com.homni.togli.application.usecase.UpdateToggleUseCase;
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
 * Integration tests for {@link ListTogglesUseCase}.
 *
 * <p>Tests filtering by enabled state and environment name — exercises
 * the dynamic WHERE clause with EXISTS subqueries in FeatureToggleJdbcAdapter.
 */
@DisplayName("ListToggles (integration)")
class ListTogglesIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired CreateToggleUseCase createToggle;
    @Autowired UpdateToggleUseCase updateToggle;
    @Autowired ListTogglesUseCase listToggles;

    AppUser admin;
    Project project;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
        project = createProject.execute(randomSlug(), "Project " + randomSuffix(), null, null);
    }

    @Test
    @DisplayName("lists all toggles without filters")
    void listsAllToggles() {
        createToggle.execute(project.id, "toggle-a-" + randomSuffix(), null, Set.of("DEV"));
        createToggle.execute(project.id, "toggle-b-" + randomSuffix(), null, Set.of("DEV"));

        TogglePage page = listToggles.execute(project.id, null, null, 0, 20);

        assertThat(page.items()).hasSizeGreaterThanOrEqualTo(2);
        assertThat(page.totalElements()).isGreaterThanOrEqualTo(2);
    }

    @Test
    @DisplayName("filters by enabled=true returns only enabled toggles")
    void filtersByEnabled() {
        FeatureToggle enabled = createToggle.execute(
                project.id, "enabled-" + randomSuffix(), null, Set.of("DEV"));
        updateToggle.execute(enabled.id, null, null, null, Map.of("DEV", true));
        createToggle.execute(project.id, "disabled-" + randomSuffix(), null, Set.of("DEV"));

        TogglePage page = listToggles.execute(project.id, true, null, 0, 20);

        assertThat(page.items()).allMatch(t -> t.isEnabledIn("DEV"));
    }

    @Test
    @DisplayName("filters by environment name")
    void filtersByEnvironment() {
        createToggle.execute(project.id, "dev-only-" + randomSuffix(), null, Set.of("DEV"));
        createToggle.execute(project.id, "prod-only-" + randomSuffix(), null, Set.of("PROD"));

        TogglePage devToggles = listToggles.execute(project.id, null, "DEV", 0, 20);

        assertThat(devToggles.items()).allMatch(t -> t.environments().contains("DEV"));
        assertThat(devToggles.items()).noneMatch(t ->
                t.environments().contains("PROD") && !t.environments().contains("DEV"));
    }

    @Test
    @DisplayName("pagination returns correct page size and total")
    void paginatesCorrectly() {
        for (int i = 0; i < 3; i++) {
            createToggle.execute(project.id, "page-" + i + "-" + randomSuffix(), null, Set.of("DEV"));
        }

        TogglePage firstPage = listToggles.execute(project.id, null, null, 0, 2);
        TogglePage secondPage = listToggles.execute(project.id, null, null, 1, 2);

        assertThat(firstPage.items()).hasSize(2);
        assertThat(firstPage.totalElements()).isGreaterThanOrEqualTo(3);
        assertThat(secondPage.items()).hasSizeGreaterThanOrEqualTo(1);
    }
}
