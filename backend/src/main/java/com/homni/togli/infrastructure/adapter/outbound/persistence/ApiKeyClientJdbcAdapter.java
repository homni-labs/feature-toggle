/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.outbound.persistence;

import com.homni.togli.application.port.out.ApiKeyClientRepositoryPort;
import com.homni.togli.application.usecase.ClientStats;
import com.homni.togli.domain.model.ApiKeyClient;
import com.homni.togli.domain.model.ApiKeyClientId;
import com.homni.togli.domain.model.ApiKeyId;
import com.homni.togli.domain.model.ClientType;
import com.homni.togli.domain.model.ProjectId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * JDBC adapter for persisting {@link ApiKeyClient} tracking entries.
 */
@Repository
public class ApiKeyClientJdbcAdapter implements ApiKeyClientRepositoryPort {

    private static final Logger log = LoggerFactory.getLogger(ApiKeyClientJdbcAdapter.class);

    private static final String COLUMNS =
            "id, api_key_id, project_id, client_type, sdk_name, service_name, namespace, first_seen_at, last_seen_at, request_count";

    private final JdbcClient jdbc;

    ApiKeyClientJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /** {@inheritDoc} */
    @Override
    public void upsert(ApiKeyClient c) {
        log.debug("Upserting API key client: apiKey={}, service={}", c.apiKeyId.value, c.serviceName);
        jdbc.sql("""
                INSERT INTO api_key_client (id, api_key_id, project_id, client_type, sdk_name, service_name, namespace, first_seen_at, last_seen_at, request_count)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (api_key_id, service_name, COALESCE(namespace, ''))
                DO UPDATE SET
                    last_seen_at = NOW(),
                    request_count = api_key_client.request_count + 1,
                    sdk_name = EXCLUDED.sdk_name,
                    client_type = EXCLUDED.client_type
                """)
                .param(c.id.value())
                .param(c.apiKeyId.value)
                .param(c.projectId.value)
                .param(c.clientType.name())
                .param(c.sdkName)
                .param(c.serviceName)
                .param(c.namespace)
                .param(Timestamp.from(c.firstSeenAt))
                .param(Timestamp.from(c.lastSeenAt))
                .param(c.requestCount)
                .update();
    }

    /** {@inheritDoc} */
    @Override
    public List<ApiKeyClient> findByApiKey(ApiKeyId apiKeyId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM api_key_client WHERE api_key_id = ? ORDER BY last_seen_at DESC")
                .param(apiKeyId.value)
                .query(this::mapRow)
                .list();
    }

    /** {@inheritDoc} */
    @Override
    public List<ApiKeyClient> findByProject(ProjectId projectId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM api_key_client WHERE project_id = ? ORDER BY last_seen_at DESC")
                .param(projectId.value)
                .query(this::mapRow)
                .list();
    }

    /** {@inheritDoc} */
    @Override
    public long countByApiKey(ApiKeyId apiKeyId) {
        return jdbc.sql("SELECT count(*) FROM api_key_client WHERE api_key_id = ?")
                .param(apiKeyId.value)
                .query(Long.class)
                .single();
    }

    /** {@inheritDoc} */
    @Override
    public Map<UUID, ClientStats> statsByApiKeys(List<ApiKeyId> apiKeyIds) {
        if (apiKeyIds.isEmpty()) {
            return Collections.emptyMap();
        }
        String placeholders = apiKeyIds.stream()
                .map(id -> "?")
                .collect(Collectors.joining(", "));

        var sql = "SELECT api_key_id, MAX(last_seen_at) AS last_used_at, COUNT(*) AS client_count"
                + " FROM api_key_client WHERE api_key_id IN (" + placeholders + ")"
                + " GROUP BY api_key_id";

        JdbcClient.StatementSpec spec = jdbc.sql(sql);
        for (ApiKeyId id : apiKeyIds) {
            spec = spec.param(id.value);
        }

        Map<UUID, ClientStats> result = new HashMap<>();
        spec.query((rs, rowNum) -> {
            UUID keyId = rs.getObject("api_key_id", UUID.class);
            Instant lastUsedAt = toInstantOrNull(rs, "last_used_at");
            long clientCount = rs.getLong("client_count");
            result.put(keyId, new ClientStats(lastUsedAt, clientCount));
            return null;
        }).list();

        return result;
    }

    private ApiKeyClient mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new ApiKeyClient(
                new ApiKeyClientId(rs.getObject("id", UUID.class)),
                new ApiKeyId(rs.getObject("api_key_id", UUID.class)),
                new ProjectId(rs.getObject("project_id", UUID.class)),
                ClientType.valueOf(rs.getString("client_type")),
                rs.getString("sdk_name"),
                rs.getString("service_name"),
                rs.getString("namespace"),
                rs.getTimestamp("first_seen_at").toInstant(),
                rs.getTimestamp("last_seen_at").toInstant(),
                rs.getLong("request_count")
        );
    }

    private Instant toInstantOrNull(ResultSet rs, String column) throws SQLException {
        Timestamp ts = rs.getTimestamp(column);
        return ts != null ? ts.toInstant() : null;
    }
}
