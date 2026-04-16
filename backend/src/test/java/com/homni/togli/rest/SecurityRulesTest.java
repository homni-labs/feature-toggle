/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.port.out.ApiKeyRepositoryPort;
import com.homni.togli.application.port.out.AppUserRepositoryPort;
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.FindOrCreateUserUseCase;
import com.homni.togli.application.usecase.GetCurrentUserUseCase;
import com.homni.togli.application.usecase.ListProjectsUseCase;
import com.homni.togli.application.usecase.ListUsersUseCase;
import com.homni.togli.application.usecase.SearchUsersUseCase;
import com.homni.togli.application.usecase.UpdateUserUseCase;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.TokenHash;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import com.homni.togli.SharedTestContainer;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration tests for Spring Security authorization rules. Uses the real
 * security filter chain with API key authentication to verify endpoint
 * access control.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("Security authorization rules")
class SecurityRulesTest {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", SharedTestContainer.PG::getJdbcUrl);
        registry.add("spring.datasource.username", SharedTestContainer.PG::getUsername);
        registry.add("spring.datasource.password", SharedTestContainer.PG::getPassword);
    }

    @Autowired MockMvc mockMvc;
    @Autowired ApiKeyRepositoryPort apiKeyRepository;
    @Autowired com.homni.togli.application.port.out.ProjectRepositoryPort projectRepository;

    @MockitoBean FindOrCreateUserUseCase findOrCreateUser;
    @MockitoBean GetCurrentUserUseCase getCurrentUser;
    @MockitoBean ListUsersUseCase listUsers;
    @MockitoBean SearchUsersUseCase searchUsers;
    @MockitoBean UpdateUserUseCase updateUser;
    @MockitoBean ListProjectsUseCase listProjects;
    @MockitoBean CreateProjectUseCase createProject;

    private String rawToken;
    private ProjectId projectId;

    @BeforeEach
    void setUpApiKey() {
        rawToken = "hft_security_" + UUID.randomUUID();
        projectId = new ProjectId();
        com.homni.togli.domain.model.Project project = new com.homni.togli.domain.model.Project(
                projectId,
                new com.homni.togli.domain.model.ProjectSlug("SEC" + UUID.randomUUID().toString().substring(0, 4).toUpperCase()),
                "Security Test", null, false, java.time.Instant.now(), null);
        projectRepository.save(project);

        TokenHash hash = TokenHash.from(rawToken);
        ApiKey key = new ApiKey(projectId, "security-test-key", ProjectRole.READER, hash, null);
        apiKeyRepository.save(key);
    }

    @Nested
    @DisplayName("unauthenticated requests")
    class Unauthenticated {

        @Test
        @DisplayName("public endpoints are accessible without auth")
        void publicEndpoints() throws Exception {
            mockMvc.perform(get("/actuator/health"))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Swagger UI is accessible without auth")
        void swaggerIsPublic() throws Exception {
            mockMvc.perform(get("/v3/api-docs"))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("protected endpoints return 401 without auth")
        void protectedEndpoints() throws Exception {
            mockMvc.perform(get("/users/me"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("401 response has JSON body with UNAUTHORIZED code")
        void unauthorizedResponseFormat() throws Exception {
            mockMvc.perform(get("/users/me"))
                    .andExpect(status().isUnauthorized())
                    .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                            .jsonPath("$.payload.code").value("UNAUTHORIZED"));
        }
    }

    @Nested
    @DisplayName("API key authentication")
    class ApiKeyAuth {

        @Test
        @DisplayName("valid API key with service header authenticates successfully")
        void validKeyAuthenticates() throws Exception {
            mockMvc.perform(get("/projects/{projectId}/toggles", projectId.value)
                            .header("X-API-Key", rawToken)
                            .header("X-Togli-Service", "test-service"))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("invalid API key returns 401")
        void invalidKeyReturns401() throws Exception {
            mockMvc.perform(get("/projects/{projectId}/toggles", projectId.value)
                            .header("X-API-Key", "hft_nonexistent")
                            .header("X-Togli-Service", "test-service"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("valid API key without X-Togli-Service header returns 400")
        void missingServiceHeader() throws Exception {
            mockMvc.perform(get("/projects/{projectId}/toggles", projectId.value)
                            .header("X-API-Key", rawToken))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("expired API key returns 401")
        void expiredKeyReturns401() throws Exception {
            String expiredToken = "hft_expired_" + UUID.randomUUID();
            TokenHash expiredHash = TokenHash.from(expiredToken);
            Instant expired = Instant.now().minus(1, ChronoUnit.DAYS);
            ApiKey expiredKey = new ApiKey(projectId, "expired-key", ProjectRole.READER, expiredHash, expired);
            apiKeyRepository.save(expiredKey);

            mockMvc.perform(get("/projects/{projectId}/toggles", projectId.value)
                            .header("X-API-Key", expiredToken)
                            .header("X-Togli-Service", "test-service"))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("role-based authorization")
    class RoleBasedAuthorization {

        @Test
        @DisplayName("API key cannot create projects (requires PLATFORM_ADMIN)")
        void apiKeyCannotCreateProject() throws Exception {
            mockMvc.perform(post("/projects")
                            .header("X-API-Key", rawToken)
                            .header("X-Togli-Service", "test-service")
                            .contentType(APPLICATION_JSON)
                            .content("""
                                    {"slug": "NEW", "name": "New"}
                                    """))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.payload.code").value("FORBIDDEN"));
        }

        @Test
        @DisplayName("API key cannot manage users (requires PLATFORM_ADMIN)")
        void apiKeyCannotManageUsers() throws Exception {
            mockMvc.perform(patch("/users/{userId}", UUID.randomUUID())
                            .header("X-API-Key", rawToken)
                            .header("X-Togli-Service", "test-service")
                            .contentType(APPLICATION_JSON)
                            .content("""
                                    {"platformRole": "PLATFORM_ADMIN"}
                                    """))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("API key can access authenticated-only endpoints")
        void apiKeyCanAccessAuthenticatedEndpoints() throws Exception {
            AppUser user = new AppUser("sub-test", "test@test.local", "Test");
            when(getCurrentUser.execute()).thenReturn(user);

            mockMvc.perform(get("/users/me")
                            .header("X-API-Key", rawToken)
                            .header("X-Togli-Service", "test-service"))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("unauthenticated request to admin endpoint returns 401, not 403")
        void unauthenticatedAdminEndpointReturns401() throws Exception {
            mockMvc.perform(post("/projects")
                            .contentType(APPLICATION_JSON)
                            .content("""
                                    {"slug": "TEST", "name": "Test"}
                                    """))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("unauthenticated request to user management returns 401")
        void unauthenticatedUserManagementReturns401() throws Exception {
            mockMvc.perform(get("/users"))
                    .andExpect(status().isUnauthorized());
        }
    }
}
