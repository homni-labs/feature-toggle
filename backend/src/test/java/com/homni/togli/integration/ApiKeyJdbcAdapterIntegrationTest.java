/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.integration;

import com.homni.togli.application.port.out.ApiKeyClientRepositoryPort;
import com.homni.togli.application.port.out.ApiKeyRepositoryPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.application.usecase.ClientStats;
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.ApiKeyClient;
import com.homni.togli.domain.model.ApiKeyId;
import com.homni.togli.domain.model.ClientType;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.TokenHash;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("ApiKey and ApiKeyClient JDBC adapters")
class ApiKeyJdbcAdapterIntegrationTest extends BaseIntegrationTest {

    @Autowired ApiKeyRepositoryPort apiKeys;
    @Autowired ApiKeyClientRepositoryPort apiKeyClients;
    @Autowired ProjectRepositoryPort projects;

    private Project project;

    @BeforeEach
    void setUp() {
        actAsAdmin(adminUser());
        project = new Project(randomSlug(), "key-test-" + randomSuffix(), null);
        projects.save(project);
    }

    @Nested
    @DisplayName("ApiKeyJdbcAdapter")
    class ApiKeyAdapter {

        @Test
        @DisplayName("saves and finds API key by id")
        void savesAndFindsById() {
            TokenHash hash = TokenHash.from("hft_test_" + UUID.randomUUID());
            ApiKey key = new ApiKey(project.id, "my-key", ProjectRole.READER, hash, null);
            apiKeys.save(key);

            Optional<ApiKey> found = apiKeys.findById(key.id);
            assertThat(found).isPresent();
            assertThat(found.get().name).isEqualTo("my-key");
            assertThat(found.get().projectRole).isEqualTo(ProjectRole.READER);
            assertThat(found.get().isActive()).isTrue();
        }

        @Test
        @DisplayName("finds active API key by token hash")
        void findsByTokenHash() {
            TokenHash hash = TokenHash.from("hft_find_" + UUID.randomUUID());
            ApiKey key = new ApiKey(project.id, "hash-key", ProjectRole.READER, hash, null);
            apiKeys.save(key);

            Optional<ApiKey> found = apiKeys.findByTokenHash(hash);
            assertThat(found).isPresent();
            assertThat(found.get().id).isEqualTo(key.id);
        }

        @Test
        @DisplayName("does not find revoked key by token hash")
        void doesNotFindRevokedByHash() {
            TokenHash hash = TokenHash.from("hft_revoked_" + UUID.randomUUID());
            ApiKey key = new ApiKey(project.id, "revoked-key", ProjectRole.READER, hash, null);
            key.revoke();
            apiKeys.save(key);

            Optional<ApiKey> found = apiKeys.findByTokenHash(hash);
            assertThat(found).isEmpty();
        }

        @Test
        @DisplayName("paginates keys by project ordered by created_at desc")
        void paginatesByProject() {
            for (int i = 0; i < 3; i++) {
                TokenHash hash = TokenHash.from("hft_page_" + UUID.randomUUID());
                apiKeys.save(new ApiKey(project.id, "key-" + i, ProjectRole.READER, hash, null));
            }

            List<ApiKey> page = apiKeys.findAllByProject(project.id, 0, 2);
            assertThat(page).hasSize(2);

            long total = apiKeys.countByProject(project.id);
            assertThat(total).isEqualTo(3);
        }

        @Test
        @DisplayName("deletes API key by id")
        void deletesById() {
            TokenHash hash = TokenHash.from("hft_del_" + UUID.randomUUID());
            ApiKey key = new ApiKey(project.id, "to-delete", ProjectRole.READER, hash, null);
            apiKeys.save(key);

            apiKeys.deleteById(key.id);

            assertThat(apiKeys.findById(key.id)).isEmpty();
        }

        @Test
        @DisplayName("persists expiration timestamp")
        void savesExpiration() {
            Instant expiresAt = Instant.now().plus(30, ChronoUnit.DAYS);
            TokenHash hash = TokenHash.from("hft_exp_" + UUID.randomUUID());
            ApiKey key = new ApiKey(project.id, "expiring", ProjectRole.READER, hash, expiresAt);
            apiKeys.save(key);

            ApiKey found = apiKeys.findById(key.id).orElseThrow();
            assertThat(found.expiresAt).isNotNull();
            assertThat(found.expiresAt.truncatedTo(ChronoUnit.SECONDS))
                    .isEqualTo(expiresAt.truncatedTo(ChronoUnit.SECONDS));
        }
    }

    @Nested
    @DisplayName("ApiKeyClientJdbcAdapter")
    class ApiKeyClientAdapter {

        private ApiKey apiKey;

        @BeforeEach
        void createKey() {
            TokenHash hash = TokenHash.from("hft_client_" + UUID.randomUUID());
            apiKey = new ApiKey(project.id, "client-key", ProjectRole.READER, hash, null);
            apiKeys.save(apiKey);
        }

        @Test
        @DisplayName("upserts client and increments request count on conflict")
        void upsertsClient() {
            ApiKeyClient client = new ApiKeyClient(
                    apiKey.id, project.id, ClientType.SDK, "togli-java", "svc-a", null);
            apiKeyClients.upsert(client);
            apiKeyClients.upsert(client);

            List<ApiKeyClient> found = apiKeyClients.findByApiKey(apiKey.id);
            assertThat(found).hasSize(1);
            assertThat(found.get(0).requestCount).isGreaterThanOrEqualTo(2);
        }

        @Test
        @DisplayName("finds clients by project")
        void findsByProject() {
            ApiKeyClient client = new ApiKeyClient(
                    apiKey.id, project.id, ClientType.REST, null, "svc-b", "ns1");
            apiKeyClients.upsert(client);

            List<ApiKeyClient> found = apiKeyClients.findByProject(project.id);
            assertThat(found).hasSize(1);
            assertThat(found.get(0).serviceName).isEqualTo("svc-b");
        }

        @Test
        @DisplayName("counts clients per API key")
        void countsByApiKey() {
            apiKeyClients.upsert(new ApiKeyClient(
                    apiKey.id, project.id, ClientType.SDK, "java", "svc-1", null));
            apiKeyClients.upsert(new ApiKeyClient(
                    apiKey.id, project.id, ClientType.REST, null, "svc-2", null));

            long count = apiKeyClients.countByApiKey(apiKey.id);
            assertThat(count).isEqualTo(2);
        }

        @Test
        @DisplayName("returns aggregated stats per API key")
        void statsByApiKeys() {
            apiKeyClients.upsert(new ApiKeyClient(
                    apiKey.id, project.id, ClientType.SDK, "java", "svc-stats", null));

            Map<UUID, ClientStats> stats = apiKeyClients.statsByApiKeys(List.of(apiKey.id));
            assertThat(stats).containsKey(apiKey.id.value);
            ClientStats s = stats.get(apiKey.id.value);
            assertThat(s.clientCount()).isEqualTo(1);
            assertThat(s.lastUsedAt()).isNotNull();
        }

        @Test
        @DisplayName("returns empty stats for empty key list")
        void emptyStatsForEmptyList() {
            Map<UUID, ClientStats> stats = apiKeyClients.statsByApiKeys(List.of());
            assertThat(stats).isEmpty();
        }
    }
}
