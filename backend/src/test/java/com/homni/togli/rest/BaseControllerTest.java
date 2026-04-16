/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homni.togli.application.usecase.CreateEnvironmentUseCase;
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.CreateToggleUseCase;
import com.homni.togli.application.usecase.DeleteApiKeyUseCase;
import com.homni.togli.application.usecase.DeleteEnvironmentUseCase;
import com.homni.togli.application.usecase.DeleteToggleUseCase;
import com.homni.togli.application.usecase.FindOrCreateUserUseCase;
import com.homni.togli.application.usecase.FindToggleUseCase;
import com.homni.togli.application.usecase.GetCurrentUserUseCase;
import com.homni.togli.application.usecase.GetProjectBySlugUseCase;
import com.homni.togli.application.usecase.IssueApiKeyUseCase;
import com.homni.togli.application.usecase.ListApiKeyClientsUseCase;
import com.homni.togli.application.usecase.ListApiKeysUseCase;
import com.homni.togli.application.usecase.ListEnvironmentsUseCase;
import com.homni.togli.application.usecase.ListMembersUseCase;
import com.homni.togli.application.usecase.ListProjectClientsUseCase;
import com.homni.togli.application.usecase.ListProjectsUseCase;
import com.homni.togli.application.usecase.ListTogglesUseCase;
import com.homni.togli.application.usecase.ListUsersUseCase;
import com.homni.togli.application.usecase.RemoveMemberUseCase;
import com.homni.togli.application.usecase.RevokeApiKeyUseCase;
import com.homni.togli.application.usecase.SearchUsersUseCase;
import com.homni.togli.application.usecase.UpdateProjectUseCase;
import com.homni.togli.application.usecase.UpdateToggleUseCase;
import com.homni.togli.application.usecase.UpdateUserUseCase;
import com.homni.togli.application.usecase.UpsertMemberUseCase;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import com.homni.togli.SharedTestContainer;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Base class for REST controller tests. Provides MockMvc with security filters
 * disabled, a shared PostgreSQL container for the Spring context, and mocked
 * use-case beans so that only the HTTP → domain → HTTP mapping is tested.
 *
 * <p>All use-case beans are mocked in this base class to ensure every controller
 * test shares the same Spring context (avoiding expensive context reloads).
 */
@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@ActiveProfiles("test")
abstract class BaseControllerTest {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", SharedTestContainer.PG::getJdbcUrl);
        registry.add("spring.datasource.username", SharedTestContainer.PG::getUsername);
        registry.add("spring.datasource.password", SharedTestContainer.PG::getPassword);
    }

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    // --- Use-case mocks (shared so all controller tests share one context) ---

    @MockitoBean protected CreateProjectUseCase createProject;
    @MockitoBean protected GetProjectBySlugUseCase getProjectBySlug;
    @MockitoBean protected ListProjectsUseCase listProjects;
    @MockitoBean protected UpdateProjectUseCase updateProject;

    @MockitoBean protected CreateToggleUseCase createToggle;
    @MockitoBean protected FindToggleUseCase findToggle;
    @MockitoBean protected ListTogglesUseCase listToggles;
    @MockitoBean protected UpdateToggleUseCase updateToggle;
    @MockitoBean protected DeleteToggleUseCase deleteToggle;

    @MockitoBean protected CreateEnvironmentUseCase createEnvironment;
    @MockitoBean protected ListEnvironmentsUseCase listEnvironments;
    @MockitoBean protected DeleteEnvironmentUseCase deleteEnvironment;

    @MockitoBean protected UpsertMemberUseCase upsertMember;
    @MockitoBean protected ListMembersUseCase listMembers;
    @MockitoBean protected RemoveMemberUseCase removeMember;

    @MockitoBean protected GetCurrentUserUseCase getCurrentUser;
    @MockitoBean protected ListUsersUseCase listUsers;
    @MockitoBean protected SearchUsersUseCase searchUsers;
    @MockitoBean protected UpdateUserUseCase updateUser;

    @MockitoBean protected IssueApiKeyUseCase issueApiKey;
    @MockitoBean protected ListApiKeysUseCase listApiKeys;
    @MockitoBean protected RevokeApiKeyUseCase revokeApiKey;
    @MockitoBean protected DeleteApiKeyUseCase deleteApiKey;
    @MockitoBean protected ListApiKeyClientsUseCase listApiKeyClients;
    @MockitoBean protected ListProjectClientsUseCase listProjectClients;

    @MockitoBean protected FindOrCreateUserUseCase findOrCreateUser;
}
