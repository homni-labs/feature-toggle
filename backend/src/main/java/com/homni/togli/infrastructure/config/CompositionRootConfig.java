/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.config;

import com.homni.togli.domain.model.EnvironmentDefaults;
import com.homni.togli.application.port.out.ApiKeyClientRepositoryPort;
import com.homni.togli.application.port.out.ApiKeyRepositoryPort;
import com.homni.togli.application.port.out.AppUserRepositoryPort;
import com.homni.togli.application.port.out.CallerPort;
import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.application.port.out.EnvironmentRepositoryPort;
import com.homni.togli.application.port.out.FeatureToggleRepositoryPort;
import com.homni.togli.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.application.usecase.CreateEnvironmentUseCase;
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.CreateToggleUseCase;
import com.homni.togli.application.usecase.DeleteApiKeyUseCase;
import com.homni.togli.application.usecase.DeleteEnvironmentUseCase;
import com.homni.togli.application.usecase.DeleteToggleUseCase;
import com.homni.togli.application.usecase.FindOrCreateUserUseCase;
import com.homni.togli.application.usecase.GetProjectBySlugUseCase;
import com.homni.togli.application.usecase.FindToggleUseCase;
import com.homni.togli.application.usecase.GetCurrentUserUseCase;
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
import com.homni.togli.application.usecase.ResolveProjectAccessUseCase;
import com.homni.togli.application.usecase.RevokeApiKeyUseCase;
import com.homni.togli.application.usecase.SearchUsersUseCase;
import com.homni.togli.application.usecase.UpdateProjectUseCase;
import com.homni.togli.application.usecase.UpdateToggleUseCase;
import com.homni.togli.application.usecase.UpdateUserUseCase;
import com.homni.togli.application.usecase.UpsertMemberUseCase;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Central wiring configuration that creates all use-case beans,
 * connecting output ports (adapters) to application-layer orchestrators.
 */
@Configuration
class CompositionRootConfig {

    // --- Toggle use-cases ---

    /**
     * Wires the CreateToggleUseCase.
     *
     * @param toggles      toggle persistence port
     * @param environments environment persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    CreateToggleUseCase createToggleUseCase(FeatureToggleRepositoryPort toggles,
                                            EnvironmentRepositoryPort environments,
                                            ProjectRepositoryPort projects,
                                            CallerProjectAccessPort callerAccess) {
        return new CreateToggleUseCase(toggles, environments, projects, callerAccess);
    }

    /**
     * Wires the FindToggleUseCase.
     *
     * @param toggles      toggle persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    FindToggleUseCase findToggleUseCase(FeatureToggleRepositoryPort toggles,
                                        CallerProjectAccessPort callerAccess) {
        return new FindToggleUseCase(toggles, callerAccess);
    }

    /**
     * Wires the ListTogglesUseCase.
     *
     * @param toggles      toggle persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    ListTogglesUseCase listTogglesUseCase(FeatureToggleRepositoryPort toggles,
                                          CallerProjectAccessPort callerAccess) {
        return new ListTogglesUseCase(toggles, callerAccess);
    }

    /**
     * Wires the UpdateToggleUseCase.
     *
     * @param toggles      toggle persistence port
     * @param environments environment persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    UpdateToggleUseCase updateToggleUseCase(FeatureToggleRepositoryPort toggles,
                                            EnvironmentRepositoryPort environments,
                                            ProjectRepositoryPort projects,
                                            CallerProjectAccessPort callerAccess) {
        return new UpdateToggleUseCase(toggles, environments, projects, callerAccess);
    }

    /**
     * Wires the DeleteToggleUseCase.
     *
     * @param toggles      toggle persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    DeleteToggleUseCase deleteToggleUseCase(FeatureToggleRepositoryPort toggles,
                                            ProjectRepositoryPort projects,
                                            CallerProjectAccessPort callerAccess) {
        return new DeleteToggleUseCase(toggles, projects, callerAccess);
    }

    // --- Project use-cases ---

    /**
     * Wires the platform-wide {@link EnvironmentDefaults} value object from the
     * raw config properties. Validation happens in the constructor — invalid
     * config fails the application startup here.
     *
     * @param properties raw config properties
     * @return the validated defaults
     */
    @Bean
    EnvironmentDefaults environmentDefaults(EnvironmentDefaultsProperties properties) {
        return new EnvironmentDefaults(properties.defaultsOrEmpty());
    }

    /**
     * Wires the CreateProjectUseCase.
     *
     * @param projects             project persistence port
     * @param environments         environment persistence port (for bootstrapping defaults)
     * @param environmentDefaults  platform-wide default environments policy
     * @return the wired use case
     */
    @Bean
    CreateProjectUseCase createProjectUseCase(ProjectRepositoryPort projects,
                                              EnvironmentRepositoryPort environments,
                                              EnvironmentDefaults environmentDefaults) {
        return new CreateProjectUseCase(projects, environments, environmentDefaults);
    }

    /**
     * Wires the GetProjectBySlugUseCase.
     *
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    GetProjectBySlugUseCase getProjectBySlugUseCase(ProjectRepositoryPort projects,
                                                    CallerProjectAccessPort callerAccess) {
        return new GetProjectBySlugUseCase(projects, callerAccess);
    }

    /**
     * Wires the ListProjectsUseCase.
     *
     * @param projects   project persistence port
     * @param callerPort caller port
     * @return the wired use case
     */
    @Bean
    ListProjectsUseCase listProjectsUseCase(ProjectRepositoryPort projects,
                                             CallerPort callerPort) {
        return new ListProjectsUseCase(projects, callerPort);
    }

    /**
     * Wires the UpdateProjectUseCase.
     *
     * @param projects     project persistence port
     * @param toggles      toggle persistence port (for bulk-disable on archive)
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    UpdateProjectUseCase updateProjectUseCase(ProjectRepositoryPort projects,
                                              FeatureToggleRepositoryPort toggles,
                                              CallerProjectAccessPort callerAccess) {
        return new UpdateProjectUseCase(projects, toggles, callerAccess);
    }

    // --- User use-cases ---

    /**
     * Wires the FindOrCreateUserUseCase.
     *
     * @param users             user persistence port
     * @param defaultAdminEmail default admin email
     * @return the wired use case
     */
    @Bean
    FindOrCreateUserUseCase findOrCreateUserUseCase(
            AppUserRepositoryPort users,
            @Value("${app.oidc.default-admin-email:}") String defaultAdminEmail) {
        return new FindOrCreateUserUseCase(users, defaultAdminEmail);
    }

    /**
     * Wires the GetCurrentUserUseCase.
     *
     * @param callerPort caller port
     * @return the wired use case
     */
    @Bean
    GetCurrentUserUseCase getCurrentUserUseCase(CallerPort callerPort) {
        return new GetCurrentUserUseCase(callerPort);
    }

    /**
     * Wires the ListUsersUseCase.
     *
     * @param users user persistence port
     * @return the wired use case
     */
    @Bean
    ListUsersUseCase listUsersUseCase(AppUserRepositoryPort users) {
        return new ListUsersUseCase(users);
    }

    /**
     * Wires the SearchUsersUseCase.
     *
     * @param users user persistence port
     * @return the wired use case
     */
    @Bean
    SearchUsersUseCase searchUsersUseCase(AppUserRepositoryPort users) {
        return new SearchUsersUseCase(users);
    }

    /**
     * Wires the UpdateUserUseCase.
     *
     * @param users      user persistence port
     * @param callerPort caller port
     * @return the wired use case
     */
    @Bean
    UpdateUserUseCase updateUserUseCase(AppUserRepositoryPort users, CallerPort callerPort) {
        return new UpdateUserUseCase(users, callerPort);
    }

    // --- API Key use-cases ---

    /**
     * Wires the IssueApiKeyUseCase.
     *
     * @param apiKeys      API key persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    IssueApiKeyUseCase issueApiKeyUseCase(ApiKeyRepositoryPort apiKeys,
                                          ProjectRepositoryPort projects,
                                          CallerProjectAccessPort callerAccess) {
        return new IssueApiKeyUseCase(apiKeys, projects, callerAccess);
    }

    /**
     * Wires the ListApiKeysUseCase.
     *
     * @param apiKeys      API key persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    ListApiKeysUseCase listApiKeysUseCase(ApiKeyRepositoryPort apiKeys,
                                          CallerProjectAccessPort callerAccess) {
        return new ListApiKeysUseCase(apiKeys, callerAccess);
    }

    /**
     * Wires the RevokeApiKeyUseCase.
     *
     * @param apiKeys      API key persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    RevokeApiKeyUseCase revokeApiKeyUseCase(ApiKeyRepositoryPort apiKeys,
                                            ProjectRepositoryPort projects,
                                            CallerProjectAccessPort callerAccess) {
        return new RevokeApiKeyUseCase(apiKeys, projects, callerAccess);
    }

    /**
     * Wires the DeleteApiKeyUseCase.
     *
     * @param apiKeys      API key persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    DeleteApiKeyUseCase deleteApiKeyUseCase(ApiKeyRepositoryPort apiKeys,
                                            ProjectRepositoryPort projects,
                                            CallerProjectAccessPort callerAccess) {
        return new DeleteApiKeyUseCase(apiKeys, projects, callerAccess);
    }

    /**
     * Wires the ListApiKeyClientsUseCase.
     *
     * @param clients      API key client persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    ListApiKeyClientsUseCase listApiKeyClientsUseCase(ApiKeyClientRepositoryPort clients,
                                                       CallerProjectAccessPort callerAccess) {
        return new ListApiKeyClientsUseCase(clients, callerAccess);
    }

    /**
     * Wires the ListProjectClientsUseCase.
     *
     * @param clients      API key client persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    ListProjectClientsUseCase listProjectClientsUseCase(ApiKeyClientRepositoryPort clients,
                                                         CallerProjectAccessPort callerAccess) {
        return new ListProjectClientsUseCase(clients, callerAccess);
    }

    // --- Environment use-cases ---

    /**
     * Wires the CreateEnvironmentUseCase.
     *
     * @param environments environment persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    CreateEnvironmentUseCase createEnvironmentUseCase(EnvironmentRepositoryPort environments,
                                                      ProjectRepositoryPort projects,
                                                      CallerProjectAccessPort callerAccess) {
        return new CreateEnvironmentUseCase(environments, projects, callerAccess);
    }

    /**
     * Wires the ListEnvironmentsUseCase.
     *
     * @param environments environment persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    ListEnvironmentsUseCase listEnvironmentsUseCase(EnvironmentRepositoryPort environments,
                                                    CallerProjectAccessPort callerAccess) {
        return new ListEnvironmentsUseCase(environments, callerAccess);
    }

    /**
     * Wires the DeleteEnvironmentUseCase.
     *
     * @param environments environment persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    DeleteEnvironmentUseCase deleteEnvironmentUseCase(EnvironmentRepositoryPort environments,
                                                      ProjectRepositoryPort projects,
                                                      CallerProjectAccessPort callerAccess) {
        return new DeleteEnvironmentUseCase(environments, projects, callerAccess);
    }

    // --- Member use-cases ---

    /**
     * Wires the UpsertMemberUseCase.
     *
     * @param memberships  membership persistence port
     * @param users        user persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    UpsertMemberUseCase upsertMemberUseCase(ProjectMembershipRepositoryPort memberships,
                                            AppUserRepositoryPort users,
                                            ProjectRepositoryPort projects,
                                            CallerProjectAccessPort callerAccess) {
        return new UpsertMemberUseCase(memberships, users, projects, callerAccess);
    }

    /**
     * Wires the ListMembersUseCase.
     *
     * @param memberships  membership persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    ListMembersUseCase listMembersUseCase(ProjectMembershipRepositoryPort memberships,
                                          CallerProjectAccessPort callerAccess) {
        return new ListMembersUseCase(memberships, callerAccess);
    }

    /**
     * Wires the RemoveMemberUseCase.
     *
     * @param memberships  membership persistence port
     * @param projects     project persistence port
     * @param callerAccess caller project access port
     * @return the wired use case
     */
    @Bean
    RemoveMemberUseCase removeMemberUseCase(ProjectMembershipRepositoryPort memberships,
                                            ProjectRepositoryPort projects,
                                            CallerProjectAccessPort callerAccess) {
        return new RemoveMemberUseCase(memberships, projects, callerAccess);
    }

    // --- Access resolution ---

    /**
     * Wires the ResolveProjectAccessUseCase.
     *
     * @param memberships membership persistence port
     * @return the wired use case
     */
    @Bean
    ResolveProjectAccessUseCase resolveProjectAccessUseCase(
            ProjectMembershipRepositoryPort memberships) {
        return new ResolveProjectAccessUseCase(memberships);
    }
}
