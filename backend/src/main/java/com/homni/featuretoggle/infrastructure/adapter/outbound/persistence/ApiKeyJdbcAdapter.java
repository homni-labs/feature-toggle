/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.outbound.persistence;

import com.homni.featuretoggle.application.port.out.ApiKeyRepositoryPort;
import com.homni.featuretoggle.domain.model.ApiKey;
import com.homni.featuretoggle.domain.model.ApiKeyId;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.ProjectRole;
import com.homni.featuretoggle.domain.model.TokenHash;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * JDBC adapter for persisting {@link ApiKey} aggregates.
 */
@Repository
public class ApiKeyJdbcAdapter implements ApiKeyRepositoryPort {

    private static final Logger log = LoggerFactory.getLogger(ApiKeyJdbcAdapter.class);

    private static final String COLUMNS =
            "id, project_id, project_role, name, token_hash, active, created_at, expires_at";

    private final JdbcClient jdbc;

    ApiKeyJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /** {@inheritDoc} */
    @Override
    public void save(ApiKey k) {
        log.debug("Persisting API key: id={}, project={}", k.id.value, k.projectId.value);
        Timestamp expiresAt = k.expiresAt != null ? Timestamp.from(k.expiresAt) : null;
        jdbc.sql("""
                INSERT INTO api_key (id, project_id, project_role, name, token_hash, active, created_at, expires_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (id) DO UPDATE
                    SET active = EXCLUDED.active,
                        expires_at = EXCLUDED.expires_at
                """)
                .param(k.id.value)
                .param(k.projectId.value)
                .param(k.projectRole.name())
                .param(k.name)
                .param(k.tokenHash.value)
                .param(k.isActive())
                .param(Timestamp.from(k.createdAt))
                .param(expiresAt)
                .update();
    }

    /** {@inheritDoc} */
    @Override
    public Optional<ApiKey> findById(ApiKeyId id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM api_key WHERE id = ?")
                .param(id.value)
                .query(this::mapRow)
                .optional();
    }

    /** {@inheritDoc} */
    @Override
    public Optional<ApiKey> findByTokenHash(TokenHash tokenHash) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM api_key WHERE token_hash = ? AND active = true")
                .param(tokenHash.value)
                .query(this::mapRow)
                .optional();
    }

    /** {@inheritDoc} */
    @Override
    public List<ApiKey> findAllByProject(ProjectId projectId, int offset, int limit) {
        return jdbc.sql("SELECT " + COLUMNS
                + " FROM api_key WHERE project_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?")
                .param(projectId.value)
                .param(limit)
                .param(offset)
                .query(this::mapRow)
                .list();
    }

    /** {@inheritDoc} */
    @Override
    public long countByProject(ProjectId projectId) {
        return jdbc.sql("SELECT count(*) FROM api_key WHERE project_id = ?")
                .param(projectId.value)
                .query(Long.class)
                .single();
    }

    /** {@inheritDoc} */
    @Override
    public void deleteById(ApiKeyId id) {
        log.debug("Deleting API key: id={}", id.value);
        jdbc.sql("DELETE FROM api_key WHERE id = ?")
                .param(id.value)
                .update();
    }

    private ApiKey mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new ApiKey(
                new ApiKeyId(rs.getObject("id", UUID.class)),
                new ProjectId(rs.getObject("project_id", UUID.class)),
                rs.getString("name"),
                ProjectRole.valueOf(rs.getString("project_role")),
                new TokenHash(rs.getString("token_hash")),
                rs.getBoolean("active"),
                rs.getTimestamp("created_at").toInstant(),
                toInstantOrNull(rs, "expires_at")
        );
    }

    private Instant toInstantOrNull(ResultSet rs, String column) throws SQLException {
        Timestamp ts = rs.getTimestamp(column);
        return ts != null ? ts.toInstant() : null;
    }
}
