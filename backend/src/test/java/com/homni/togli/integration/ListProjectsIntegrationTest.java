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
import com.homni.togli.application.usecase.ListProjectsUseCase;
import com.homni.togli.application.usecase.ProjectPage;
import com.homni.togli.application.usecase.UpdateProjectUseCase;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.Project;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for {@link ListProjectsUseCase}.
 *
 * <p>Tests the most complex SQL in the system: visibility rules,
 * text search, archived filter, and aggregated counters.
 */
@DisplayName("ListProjects (integration)")
class ListProjectsIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired ListProjectsUseCase listProjects;
    @Autowired UpdateProjectUseCase updateProject;

    AppUser admin;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
    }

    @Test
    @DisplayName("returns created projects with correct counters")
    void returnsCreatedProjects() {
        String suffix = randomSuffix();
        createProject.execute(randomSlug(), "List-" + suffix, null, null);

        ProjectPage page = listProjects.execute("List-" + suffix, null, 0, 20);

        assertThat(page.items()).isNotEmpty();
        assertThat(page.items().getFirst().project().name()).isEqualTo("List-" + suffix);
        assertThat(page.items().getFirst().environmentsCount()).isEqualTo(3);
    }

    @Test
    @DisplayName("filters by text search on name")
    void filtersByTextSearch() {
        String unique = "UNIQUE" + randomSuffix();
        createProject.execute(randomSlug(), unique, null, null);
        createProject.execute(randomSlug(), "Other " + randomSuffix(), null, null);

        ProjectPage page = listProjects.execute(unique, null, 0, 20);

        assertThat(page.items()).hasSize(1);
        assertThat(page.items().getFirst().project().name()).isEqualTo(unique);
    }

    @Test
    @DisplayName("filters by archived status")
    void filtersByArchived() {
        Project active = createProject.execute(randomSlug(), "Active " + randomSuffix(), null, null);
        Project archived = createProject.execute(randomSlug(), "Archived " + randomSuffix(), null, null);
        updateProject.execute(archived.id, null, null, true);

        ProjectPage archivedOnly = listProjects.execute(null, true, 0, 20);

        assertThat(archivedOnly.items())
                .anyMatch(item -> item.project().id.equals(archived.id));
        assertThat(archivedOnly.items())
                .noneMatch(item -> item.project().id.equals(active.id));
    }

    @Test
    @DisplayName("totalCount and archivedCount are stable regardless of search filter")
    void countersStableAcrossFilters() {
        String unique = "COUNTER" + randomSuffix();
        createProject.execute(randomSlug(), unique, null, null);

        ProjectPage withSearch = listProjects.execute(unique, null, 0, 20);
        ProjectPage withoutSearch = listProjects.execute(null, null, 0, 20);

        assertThat(withSearch.totalCount()).isEqualTo(withoutSearch.totalCount());
        assertThat(withSearch.archivedCount()).isEqualTo(withoutSearch.archivedCount());
    }
}
