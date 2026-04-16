/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.usecase.EnvironmentPage;
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.exception.EnvironmentInUseException;
import com.homni.togli.domain.model.Environment;
import com.homni.togli.domain.model.EnvironmentId;
import com.homni.togli.domain.model.ProjectId;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class EnvironmentsControllerTest extends BaseControllerTest {

    private final UUID projectId = UUID.randomUUID();

    @Nested
    @DisplayName("POST /projects/{projectId}/environments")
    class CreateEnvironment {

        @Test
        @DisplayName("passes projectId and name to use case and returns full payload")
        void createsEnvironment() throws Exception {
            Environment env = new Environment(new ProjectId(projectId), "STAGING");
            when(createEnvironment.execute(eq(new ProjectId(projectId)), eq("STAGING"))).thenReturn(env);

            mockMvc.perform(post("/projects/{projectId}/environments", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name": "STAGING"}
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(env.id.value.toString()))
                    .andExpect(jsonPath("$.payload.projectId").value(projectId.toString()))
                    .andExpect(jsonPath("$.payload.name").value("STAGING"))
                    .andExpect(jsonPath("$.payload.createdAt").exists())
                    .andExpect(jsonPath("$.meta.timestamp").exists());

            verify(createEnvironment).execute(eq(new ProjectId(projectId)), eq("STAGING"));
        }

        @Test
        @DisplayName("returns 400 when name is blank")
        void rejectsBlankName() throws Exception {
            mockMvc.perform(post("/projects/{projectId}/environments", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name": ""}
                                    """))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("returns 400 when name is missing")
        void rejectsMissingName() throws Exception {
            mockMvc.perform(post("/projects/{projectId}/environments", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("returns 409 when environment already exists")
        void rejectsDuplicate() throws Exception {
            when(createEnvironment.execute(any(), any()))
                    .thenThrow(new AlreadyExistsException("Environment", "DEV"));

            mockMvc.perform(post("/projects/{projectId}/environments", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name": "DEV"}
                                    """))
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.payload.code").value("CONFLICT"));
        }
    }

    @Nested
    @DisplayName("GET /projects/{projectId}/environments")
    class ListEnvironments {

        @Test
        @DisplayName("passes projectId and pagination to use case, returns full items")
        void returnsList() throws Exception {
            Environment env = new Environment(new ProjectId(projectId), "DEV");
            EnvironmentPage page = new EnvironmentPage(List.of(env), 1L);
            when(listEnvironments.execute(eq(new ProjectId(projectId)), eq(1), eq(10))).thenReturn(page);

            mockMvc.perform(get("/projects/{projectId}/environments", projectId)
                            .param("page", "1").param("size", "10"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].id").value(env.id.value.toString()))
                    .andExpect(jsonPath("$.payload[0].projectId").value(projectId.toString()))
                    .andExpect(jsonPath("$.payload[0].name").value("DEV"))
                    .andExpect(jsonPath("$.payload[0].createdAt").exists())
                    .andExpect(jsonPath("$.pagination.totalElements").value(1))
                    .andExpect(jsonPath("$.pagination.page").value(1))
                    .andExpect(jsonPath("$.pagination.size").value(10));

            verify(listEnvironments).execute(eq(new ProjectId(projectId)), eq(1), eq(10));
        }
    }

    @Nested
    @DisplayName("GET /environments/defaults")
    class ListDefaults {

        @Test
        @DisplayName("returns default environment names from configuration")
        void returnsDefaults() throws Exception {
            mockMvc.perform(get("/environments/defaults"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload").isArray())
                    .andExpect(jsonPath("$.payload", contains("DEV", "TEST", "PROD")));
        }
    }

    @Nested
    @DisplayName("DELETE /projects/{projectId}/environments/{environmentId}")
    class DeleteEnvironment {

        @Test
        @DisplayName("deletes environment and returns 204")
        void deletesEnvironment() throws Exception {
            UUID envId = UUID.randomUUID();

            mockMvc.perform(delete("/projects/{projectId}/environments/{environmentId}",
                            projectId, envId))
                    .andExpect(status().isNoContent());

            verify(deleteEnvironment).execute(eq(new EnvironmentId(envId)), eq(new ProjectId(projectId)));
        }

        @Test
        @DisplayName("returns 409 when environment is still in use")
        void rejectsInUse() throws Exception {
            UUID envId = UUID.randomUUID();
            org.mockito.Mockito.doThrow(new EnvironmentInUseException("DEV"))
                    .when(deleteEnvironment).execute(any(), any());

            mockMvc.perform(delete("/projects/{projectId}/environments/{environmentId}",
                            projectId, envId))
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.payload.code").value("CONFLICT"));
        }
    }
}
