/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.usecase.TogglePage;
import com.homni.togli.domain.exception.DomainValidationException;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.FeatureToggleId;
import com.homni.togli.domain.model.ProjectId;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FeatureTogglesControllerTest extends BaseControllerTest {

    private final UUID projectId = UUID.randomUUID();

    @Nested
    @DisplayName("POST /projects/{projectId}/toggles")
    class CreateToggle {

        @Test
        @DisplayName("creates toggle and returns full payload")
        void createsToggle() throws Exception {
            ProjectId pid = new ProjectId(projectId);
            Set<String> envs = Set.of("DEV", "PROD");
            FeatureToggle toggle = new FeatureToggle(pid, "dark-mode", "desc", envs, envs);
            when(createToggle.execute(any(ProjectId.class), eq("dark-mode"), eq("desc"), any()))
                    .thenReturn(toggle);

            mockMvc.perform(post("/projects/{projectId}/toggles", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name":"dark-mode","description":"desc","environments":["DEV","PROD"]}
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(toggle.id.value.toString()))
                    .andExpect(jsonPath("$.payload.projectId").value(projectId.toString()))
                    .andExpect(jsonPath("$.payload.name").value("dark-mode"))
                    .andExpect(jsonPath("$.payload.description").value("desc"))
                    .andExpect(jsonPath("$.payload.environments").isArray())
                    .andExpect(jsonPath("$.payload.environments", hasSize(2)))
                    .andExpect(jsonPath("$.payload.environments[0].name").exists())
                    .andExpect(jsonPath("$.payload.environments[0].enabled").value(false))
                    .andExpect(jsonPath("$.payload.createdAt").exists())
                    .andExpect(jsonPath("$.meta.timestamp").exists());
        }

        @Test
        @DisplayName("returns 400 when name is blank")
        void rejectsBlankName() throws Exception {
            mockMvc.perform(post("/projects/{projectId}/toggles", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name":"","environments":["DEV"]}
                                    """))
                    .andExpect(status().isBadRequest());
        }


        @Test
        @DisplayName("returns 422 when domain validation fails")
        void rejectsInvalidToggle() throws Exception {
            when(createToggle.execute(any(), any(), any(), any()))
                    .thenThrow(new DomainValidationException("Toggle must have at least one environment"));

            mockMvc.perform(post("/projects/{projectId}/toggles", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name":"valid-name","environments":["UNKNOWN"]}
                                    """))
                    .andExpect(status().isUnprocessableEntity())
                    .andExpect(jsonPath("$.payload.code").value("VALIDATION_ERROR"));
        }
    }

    @Nested
    @DisplayName("GET /projects/{projectId}/toggles/{toggleId}")
    class GetToggle {

        @Test
        @DisplayName("returns toggle by id with environments")
        void returnsToggle() throws Exception {
            UUID toggleId = UUID.randomUUID();
            FeatureToggle toggle = new FeatureToggle(
                    new FeatureToggleId(toggleId), new ProjectId(projectId),
                    "my-flag", null, Map.of("DEV", true), java.time.Instant.now(), null);
            when(findToggle.execute(any(FeatureToggleId.class))).thenReturn(toggle);

            mockMvc.perform(get("/projects/{projectId}/toggles/{toggleId}",
                            projectId, toggleId))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(toggleId.toString()))
                    .andExpect(jsonPath("$.payload.projectId").value(projectId.toString()))
                    .andExpect(jsonPath("$.payload.name").value("my-flag"))
                    .andExpect(jsonPath("$.payload.environments", hasSize(1)))
                    .andExpect(jsonPath("$.payload.environments[0].name").value("DEV"))
                    .andExpect(jsonPath("$.payload.environments[0].enabled").value(true))
                    .andExpect(jsonPath("$.payload.createdAt").exists());
        }

        @Test
        @DisplayName("returns 404 when toggle not found")
        void returnsNotFound() throws Exception {
            UUID toggleId = UUID.randomUUID();
            when(findToggle.execute(any()))
                    .thenThrow(new EntityNotFoundException("Toggle", toggleId));

            mockMvc.perform(get("/projects/{projectId}/toggles/{toggleId}",
                            projectId, toggleId))
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.payload.code").value("NOT_FOUND"));
        }
    }

    @Nested
    @DisplayName("GET /projects/{projectId}/toggles")
    class ListToggles {

        @Test
        @DisplayName("returns paginated toggle list with content")
        void returnsList() throws Exception {
            Set<String> envs = Set.of("DEV");
            FeatureToggle toggle = new FeatureToggle(
                    new ProjectId(projectId), "flag-1", null, envs, envs);
            TogglePage page = new TogglePage(List.of(toggle), 1L);
            when(listToggles.execute(any(), any(), any(), eq(0), eq(20))).thenReturn(page);

            mockMvc.perform(get("/projects/{projectId}/toggles", projectId))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].id").value(toggle.id.value.toString()))
                    .andExpect(jsonPath("$.payload[0].name").value("flag-1"))
                    .andExpect(jsonPath("$.payload[0].environments", hasSize(1)))
                    .andExpect(jsonPath("$.pagination.totalElements").value(1))
                    .andExpect(jsonPath("$.pagination.page").value(0))
                    .andExpect(jsonPath("$.pagination.size").value(20));
        }

        @Test
        @DisplayName("applies default pagination when params are omitted")
        void appliesDefaultPagination() throws Exception {
            TogglePage page = new TogglePage(List.of(), 0L);
            when(listToggles.execute(any(), any(), any(), eq(0), eq(20))).thenReturn(page);

            mockMvc.perform(get("/projects/{projectId}/toggles", projectId))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.pagination.page").value(0))
                    .andExpect(jsonPath("$.pagination.size").value(20));

            verify(listToggles).execute(any(), any(), any(), eq(0), eq(20));
        }

        @Test
        @DisplayName("passes filter parameters to use case")
        void passesFilters() throws Exception {
            TogglePage page = new TogglePage(List.of(), 0L);
            when(listToggles.execute(any(), eq(true), eq("PROD"), eq(0), eq(20)))
                    .thenReturn(page);

            mockMvc.perform(get("/projects/{projectId}/toggles", projectId)
                            .param("enabled", "true")
                            .param("environment", "PROD"))
                    .andExpect(status().isOk());

            verify(listToggles).execute(any(ProjectId.class), eq(true), eq("PROD"), eq(0), eq(20));
        }
    }

    @Nested
    @DisplayName("PATCH /projects/{projectId}/toggles/{toggleId}")
    class UpdateToggle {

        @Test
        @DisplayName("updates toggle and returns full payload with environments")
        void updatesToggle() throws Exception {
            UUID toggleId = UUID.randomUUID();
            FeatureToggle toggle = new FeatureToggle(
                    new FeatureToggleId(toggleId), new ProjectId(projectId),
                    "renamed", "new desc", Map.of("DEV", false, "PROD", true),
                    java.time.Instant.now(), null);
            when(updateToggle.execute(any(), any(), any(), any(), any())).thenReturn(toggle);

            mockMvc.perform(patch("/projects/{projectId}/toggles/{toggleId}",
                            projectId, toggleId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name":"renamed"}
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(toggleId.toString()))
                    .andExpect(jsonPath("$.payload.projectId").value(projectId.toString()))
                    .andExpect(jsonPath("$.payload.name").value("renamed"))
                    .andExpect(jsonPath("$.payload.description").value("new desc"))
                    .andExpect(jsonPath("$.payload.environments", hasSize(2)));
        }
    }

    @Nested
    @DisplayName("path variable validation")
    class PathVariableValidation {

        @Test
        @DisplayName("returns 400 when toggleId is not a valid UUID")
        void rejectsNonUuidToggleId() throws Exception {
            mockMvc.perform(get("/projects/{projectId}/toggles/{toggleId}",
                            projectId, "not-a-uuid"))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("DELETE /projects/{projectId}/toggles/{toggleId}")
    class DeleteToggle {

        @Test
        @DisplayName("deletes toggle and returns 204")
        void deletesToggle() throws Exception {
            UUID toggleId = UUID.randomUUID();

            mockMvc.perform(delete("/projects/{projectId}/toggles/{toggleId}",
                            projectId, toggleId))
                    .andExpect(status().isNoContent());

            verify(deleteToggle).execute(eq(new FeatureToggleId(toggleId)));
        }

        @Test
        @DisplayName("returns 404 when toggle does not exist")
        void returnsNotFound() throws Exception {
            UUID toggleId = UUID.randomUUID();
            org.mockito.Mockito.doThrow(new EntityNotFoundException("Toggle", toggleId))
                    .when(deleteToggle).execute(any());

            mockMvc.perform(delete("/projects/{projectId}/toggles/{toggleId}",
                            projectId, toggleId))
                    .andExpect(status().isNotFound());
        }
    }
}
