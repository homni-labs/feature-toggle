/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.usecase.ApiKeyPage;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.InvalidStateException;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.ApiKeyClient;
import com.homni.togli.domain.model.ApiKeyId;
import com.homni.togli.domain.model.ClientType;
import com.homni.togli.domain.model.IssuedApiKey;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.TokenHash;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.startsWith;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ApiKeysControllerTest extends BaseControllerTest {

    private final UUID projectId = UUID.randomUUID();

    @Nested
    @DisplayName("POST /projects/{projectId}/api-keys")
    class IssueApiKey {

        @Test
        @DisplayName("issues API key and returns full created payload")
        void issuesApiKey() throws Exception {
            IssuedApiKey issued = new IssuedApiKey(new ProjectId(projectId), "ci-key", null);
            when(issueApiKey.execute(any(ProjectId.class), eq("ci-key"), any())).thenReturn(issued);

            mockMvc.perform(post("/projects/{projectId}/api-keys", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name": "ci-key"}
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(issued.apiKey.id.value.toString()))
                    .andExpect(jsonPath("$.payload.name").value("ci-key"))
                    .andExpect(jsonPath("$.payload.role").value("READER"))
                    .andExpect(jsonPath("$.payload.rawToken", startsWith("hft_")))
                    .andExpect(jsonPath("$.payload.createdAt").exists())
                    .andExpect(jsonPath("$.meta.timestamp").exists());
        }

        @Test
        @DisplayName("returns 400 when name is blank")
        void rejectsBlankName() throws Exception {
            mockMvc.perform(post("/projects/{projectId}/api-keys", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"name": ""}
                                    """))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("returns 400 when name is missing")
        void rejectsMissingName() throws Exception {
            mockMvc.perform(post("/projects/{projectId}/api-keys", projectId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /projects/{projectId}/api-keys")
    class ListApiKeys {

        @Test
        @DisplayName("passes projectId and pagination to use case, returns list")
        void returnsList() throws Exception {
            ProjectId pid = new ProjectId(projectId);
            TokenHash hash = TokenHash.from("hft_test_token");
            ApiKey key = new ApiKey(pid, "read-key", ProjectRole.READER, hash, null);
            ApiKeyPage page = new ApiKeyPage(List.of(key), 1L);
            when(listApiKeys.execute(eq(pid), eq(1), eq(10))).thenReturn(page);

            mockMvc.perform(get("/projects/{projectId}/api-keys", projectId)
                            .param("page", "1").param("size", "10"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].name").value("read-key"))
                    .andExpect(jsonPath("$.payload[0].role").value("READER"))
                    .andExpect(jsonPath("$.payload[0].active").value(true))
                    .andExpect(jsonPath("$.pagination.totalElements").value(1));

            verify(listApiKeys).execute(eq(pid), eq(1), eq(10));
        }
    }

    @Nested
    @DisplayName("DELETE /projects/{projectId}/api-keys/{apiKeyId}")
    class RevokeApiKey {

        @Test
        @DisplayName("revokes API key and returns 204")
        void revokesKey() throws Exception {
            UUID keyId = UUID.randomUUID();

            mockMvc.perform(delete("/projects/{projectId}/api-keys/{apiKeyId}",
                            projectId, keyId))
                    .andExpect(status().isNoContent());

            verify(revokeApiKey).execute(eq(new ApiKeyId(keyId)));
        }
    }

    @Nested
    @DisplayName("DELETE /projects/{projectId}/api-keys/{apiKeyId}/permanently")
    class DeleteApiKey {

        @Test
        @DisplayName("permanently deletes revoked API key and returns 204")
        void deletesKey() throws Exception {
            UUID keyId = UUID.randomUUID();

            mockMvc.perform(delete("/projects/{projectId}/api-keys/{apiKeyId}/permanently",
                            projectId, keyId))
                    .andExpect(status().isNoContent());

            verify(deleteApiKey).execute(eq(new ApiKeyId(keyId)));
        }

        @Test
        @DisplayName("returns 409 when API key is still active")
        void rejectsActiveKey() throws Exception {
            UUID keyId = UUID.randomUUID();
            org.mockito.Mockito.doThrow(new InvalidStateException("API key is still active"))
                    .when(deleteApiKey).execute(any());

            mockMvc.perform(delete("/projects/{projectId}/api-keys/{apiKeyId}/permanently",
                            projectId, keyId))
                    .andExpect(status().isConflict());
        }
    }

    @Nested
    @DisplayName("GET /projects/{projectId}/api-keys/{apiKeyId}/clients")
    class ListApiKeyClients {

        @Test
        @DisplayName("returns client list with full item content")
        void returnsClients() throws Exception {
            UUID keyId = UUID.randomUUID();
            ApiKeyClient client = new ApiKeyClient(
                    new ApiKeyId(keyId), new ProjectId(projectId),
                    ClientType.SDK, "togli-java", "my-service", null);
            when(listApiKeyClients.execute(any(), any())).thenReturn(List.of(client));

            mockMvc.perform(get("/projects/{projectId}/api-keys/{apiKeyId}/clients",
                            projectId, keyId))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].apiKeyId").value(keyId.toString()))
                    .andExpect(jsonPath("$.payload[0].clientType").value("SDK"))
                    .andExpect(jsonPath("$.payload[0].sdkName").value("togli-java"))
                    .andExpect(jsonPath("$.payload[0].serviceName").value("my-service"))
                    .andExpect(jsonPath("$.payload[0].firstSeenAt").exists())
                    .andExpect(jsonPath("$.payload[0].lastSeenAt").exists())
                    .andExpect(jsonPath("$.payload[0].requestCount").value(1));
        }
    }

    @Nested
    @DisplayName("GET /projects/{projectId}/api-keys/clients")
    class ListProjectClients {

        @Test
        @DisplayName("returns all clients for project with full content")
        void returnsProjectClients() throws Exception {
            UUID keyId = UUID.randomUUID();
            ApiKeyClient client = new ApiKeyClient(
                    new ApiKeyId(keyId), new ProjectId(projectId),
                    ClientType.REST, null, "billing-service", "production");
            when(listProjectClients.execute(any())).thenReturn(List.of(client));

            mockMvc.perform(get("/projects/{projectId}/api-keys/clients", projectId))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].apiKeyId").value(keyId.toString()))
                    .andExpect(jsonPath("$.payload[0].clientType").value("REST"))
                    .andExpect(jsonPath("$.payload[0].serviceName").value("billing-service"))
                    .andExpect(jsonPath("$.payload[0].namespace").value("production"))
                    .andExpect(jsonPath("$.payload[0].requestCount").value(1));
        }

        @Test
        @DisplayName("returns empty list when no clients exist")
        void returnsEmptyList() throws Exception {
            when(listProjectClients.execute(any())).thenReturn(List.of());

            mockMvc.perform(get("/projects/{projectId}/api-keys/clients", projectId))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(0)));
        }
    }
}
