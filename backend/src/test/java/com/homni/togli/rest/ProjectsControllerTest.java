/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.usecase.ProjectListItem;
import com.homni.togli.application.usecase.ProjectPage;
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.ProjectArchivedException;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.ProjectSlug;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ProjectsControllerTest extends BaseControllerTest {

    @Nested
    @DisplayName("POST /projects")
    class CreateProject {

        @Test
        @DisplayName("creates project and passes correct arguments to use case")
        void createsProject() throws Exception {
            Project project = new Project(new ProjectSlug("MY_PROJECT"), "My Project", "desc");
            when(createProject.execute(any(), any(), any(), any())).thenReturn(project);

            mockMvc.perform(post("/projects")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"slug": "MY_PROJECT", "name": "My Project", "description": "desc"}
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(project.id.value.toString()))
                    .andExpect(jsonPath("$.payload.slug").value("MY_PROJECT"))
                    .andExpect(jsonPath("$.payload.name").value("My Project"))
                    .andExpect(jsonPath("$.payload.description").value("desc"))
                    .andExpect(jsonPath("$.payload.archived").value(false))
                    .andExpect(jsonPath("$.payload.createdAt").exists())
                    .andExpect(jsonPath("$.payload.togglesCount").value(0))
                    .andExpect(jsonPath("$.payload.environmentsCount").value(0))
                    .andExpect(jsonPath("$.payload.membersCount").value(0))
                    .andExpect(jsonPath("$.meta.timestamp").exists());

            verify(createProject).execute(
                    eq(new ProjectSlug("MY_PROJECT")), eq("My Project"), eq("desc"), any());
        }

        @Test
        @DisplayName("returns 400 when required fields are missing")
        void rejectsMissingName() throws Exception {
            mockMvc.perform(post("/projects")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"slug": "NO_NAME"}
                                    """))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("returns 400 when slug has invalid format")
        void rejectsInvalidSlugFormat() throws Exception {
            mockMvc.perform(post("/projects")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"slug": "123_BAD", "name": "Name"}
                                    """))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("returns 400 when name is blank")
        void rejectsBlankName() throws Exception {
            mockMvc.perform(post("/projects")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"slug": "VALID_SLUG", "name": ""}
                                    """))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("returns 409 when slug already exists")
        void rejectsDuplicateSlug() throws Exception {
            when(createProject.execute(any(), any(), any(), any()))
                    .thenThrow(new AlreadyExistsException("Project", "MY_PROJECT"));

            mockMvc.perform(post("/projects")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"slug": "MY_PROJECT", "name": "My Project"}
                                    """))
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.payload.code").value("CONFLICT"));
        }
    }

    @Nested
    @DisplayName("GET /projects/by-slug/{slug}")
    class GetBySlug {

        @Test
        @DisplayName("passes slug from URL path to use case and returns project")
        void returnsProject() throws Exception {
            Project project = new Project(new ProjectSlug("DEMO"), "Demo", null);
            when(getProjectBySlug.execute(eq(new ProjectSlug("DEMO")))).thenReturn(project);

            mockMvc.perform(get("/projects/by-slug/DEMO"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(project.id.value.toString()))
                    .andExpect(jsonPath("$.payload.slug").value("DEMO"))
                    .andExpect(jsonPath("$.payload.name").value("Demo"))
                    .andExpect(jsonPath("$.payload.archived").value(false))
                    .andExpect(jsonPath("$.payload.createdAt").exists());

            verify(getProjectBySlug).execute(eq(new ProjectSlug("DEMO")));
        }

        @Test
        @DisplayName("returns 404 when slug not found")
        void returnsNotFound() throws Exception {
            when(getProjectBySlug.execute(any()))
                    .thenThrow(new EntityNotFoundException("Project", "MISSING"));

            mockMvc.perform(get("/projects/by-slug/MISSING"))
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.payload.code").value("NOT_FOUND"));
        }
    }

    @Nested
    @DisplayName("GET /projects")
    class ListProjects {

        @Test
        @DisplayName("returns paginated project list with counts and role")
        void returnsList() throws Exception {
            Project project = new Project(new ProjectSlug("ALPHA"), "Alpha", null);
            ProjectListItem item = new ProjectListItem(project, ProjectRole.ADMIN, 5, 3, 2);
            ProjectPage page = new ProjectPage(List.of(item), 1L, 1L, 0L);
            when(listProjects.execute(any(), any(), eq(0), eq(20))).thenReturn(page);

            mockMvc.perform(get("/projects"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].id").value(project.id.value.toString()))
                    .andExpect(jsonPath("$.payload[0].slug").value("ALPHA"))
                    .andExpect(jsonPath("$.payload[0].name").value("Alpha"))
                    .andExpect(jsonPath("$.payload[0].archived").value(false))
                    .andExpect(jsonPath("$.payload[0].togglesCount").value(5))
                    .andExpect(jsonPath("$.payload[0].environmentsCount").value(3))
                    .andExpect(jsonPath("$.payload[0].membersCount").value(2))
                    .andExpect(jsonPath("$.payload[0].myRole").value("ADMIN"))
                    .andExpect(jsonPath("$.pagination.totalElements").value(1))
                    .andExpect(jsonPath("$.totalCount").value(1))
                    .andExpect(jsonPath("$.archivedCount").value(0))
                    .andExpect(jsonPath("$.meta.timestamp").exists());
        }
    }

    @Nested
    @DisplayName("PATCH /projects/{projectId}")
    class UpdateProject {

        @Test
        @DisplayName("updates project name and returns full payload")
        void updatesProject() throws Exception {
            UUID projectId = UUID.randomUUID();
            Project updated = new Project(new ProjectSlug("DEMO"), "New Name", "description");
            when(updateProject.execute(any(ProjectId.class), eq("New Name"), any(), any()))
                    .thenReturn(updated);

            mockMvc.perform(patch("/projects/{projectId}", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name": "New Name"}
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(updated.id.value.toString()))
                    .andExpect(jsonPath("$.payload.slug").value("DEMO"))
                    .andExpect(jsonPath("$.payload.name").value("New Name"))
                    .andExpect(jsonPath("$.payload.description").value("description"))
                    .andExpect(jsonPath("$.payload.archived").value(false))
                    .andExpect(jsonPath("$.payload.createdAt").exists());
        }

        @Test
        @DisplayName("returns 409 when project is archived")
        void rejectsArchivedProject() throws Exception {
            UUID projectId = UUID.randomUUID();
            when(updateProject.execute(any(), any(), any(), any()))
                    .thenThrow(new ProjectArchivedException(new ProjectId(projectId)));

            mockMvc.perform(patch("/projects/{projectId}", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name": "Nope"}
                                    """))
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.payload.code").value("CONFLICT"));
        }

        @Test
        @DisplayName("returns 404 when project does not exist")
        void returnsNotFound() throws Exception {
            UUID projectId = UUID.randomUUID();
            when(updateProject.execute(any(), any(), any(), any()))
                    .thenThrow(new EntityNotFoundException("Project", projectId));

            mockMvc.perform(patch("/projects/{projectId}", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name": "X"}
                                    """))
                    .andExpect(status().isNotFound());
        }
    }
}
