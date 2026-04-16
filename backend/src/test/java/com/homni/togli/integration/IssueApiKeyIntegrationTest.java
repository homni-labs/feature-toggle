/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.integration;

import com.homni.togli.application.port.out.ApiKeyRepositoryPort;
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.IssueApiKeyUseCase;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.IssuedApiKey;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.TokenHash;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for {@link IssueApiKeyUseCase}.
 */
@DisplayName("IssueApiKey (integration)")
class IssueApiKeyIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired IssueApiKeyUseCase issueApiKey;
    @Autowired ApiKeyRepositoryPort apiKeys;

    AppUser admin;
    Project project;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
        project = createProject.execute(randomSlug(), "Project " + randomSuffix(), null, null);
    }

    @Test
    @DisplayName("issues API key persisted in database with hashed token")
    void issuesApiKey() {
        IssuedApiKey issued = issueApiKey.execute(
                project.id, "sdk-key-" + randomSuffix(), null);

        assertThat(issued.rawToken).startsWith("hft_");
        assertThat(issued.apiKey.isActive()).isTrue();
        assertThat(issued.apiKey.projectRole).isEqualTo(ProjectRole.READER);

        ApiKey fromDb = apiKeys.findById(issued.apiKey.id).orElseThrow();
        assertThat(fromDb.isActive()).isTrue();
    }

    @Test
    @DisplayName("token hash in database matches raw token hash")
    void tokenHashMatchesRawToken() {
        IssuedApiKey issued = issueApiKey.execute(
                project.id, "hash-key-" + randomSuffix(), null);

        TokenHash expectedHash = TokenHash.from(issued.rawToken);
        ApiKey fromDb = apiKeys.findById(issued.apiKey.id).orElseThrow();
        assertThat(fromDb.tokenHash).isEqualTo(expectedHash);
    }

    @Test
    @DisplayName("issues API key with expiration")
    void issuesWithExpiration() {
        Instant expiresAt = Instant.now().plus(90, ChronoUnit.DAYS);

        IssuedApiKey issued = issueApiKey.execute(
                project.id, "expiring-" + randomSuffix(), expiresAt);

        assertThat(issued.apiKey.expiresAt).isEqualTo(expiresAt);
        assertThat(issued.apiKey.isValid()).isTrue();
    }
}
