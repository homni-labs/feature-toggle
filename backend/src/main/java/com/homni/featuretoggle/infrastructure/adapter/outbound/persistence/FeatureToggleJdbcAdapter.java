/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.outbound.persistence;

import com.homni.featuretoggle.application.port.out.FeatureToggleRepositoryPort;
import com.homni.featuretoggle.domain.model.FeatureToggle;
import com.homni.featuretoggle.domain.model.FeatureToggleId;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.exception.AlreadyExistsException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Array;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * JDBC adapter for persisting {@link FeatureToggle} aggregates scoped to a project.
 */
@Repository
public class FeatureToggleJdbcAdapter implements FeatureToggleRepositoryPort {

    private static final String SELECT_WITH_ENVS = """
            SELECT ft.id, ft.project_id, ft.name, ft.description, ft.enabled, ft.created_at, ft.updated_at,
                   (SELECT COALESCE(array_agg(e.name ORDER BY e.name), '{}')
                    FROM toggle_environment te
                    JOIN environment e ON e.id = te.environment_id
                    WHERE te.toggle_id = ft.id) AS environments
            FROM feature_toggle ft""";

    private final JdbcClient jdbc;

    FeatureToggleJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Saves a toggle via upsert and syncs environment associations.
     *
     * @param t the toggle to save
     */
    @Override
    @Transactional
    public void save(FeatureToggle t) {
        upsertToggle(t);
        syncEnvironments(t);
    }

    /**
     * Finds a toggle by identity.
     *
     * @param id the toggle identity
     * @return the toggle, or empty
     */
    @Override
    public Optional<FeatureToggle> findById(FeatureToggleId id) {
        return jdbc.sql(SELECT_WITH_ENVS + " WHERE ft.id = ?")
                .param(id.value)
                .query(this::mapRow)
                .optional();
    }

    /**
     * Lists toggles for a project with optional filters and pagination.
     *
     * @param projectId   owning project identity
     * @param enabled     enabled filter, or null
     * @param environment environment filter, or null
     * @param offset      rows to skip
     * @param limit       max rows to return
     * @return matching toggles
     */
    @Override
    public List<FeatureToggle> findAllByProject(ProjectId projectId, Boolean enabled,
                                                 String environment, int offset, int limit) {
        WhereClause where = buildWhere(projectId, enabled, environment);
        JdbcClient.StatementSpec spec = jdbc.sql(
                SELECT_WITH_ENVS + where.sql + " ORDER BY ft.name LIMIT ? OFFSET ?");
        for (Object param : where.params) {
            spec = spec.param(param);
        }
        return spec.param(limit).param(offset).query(this::mapRow).list();
    }

    /**
     * Counts toggles matching the given filters.
     *
     * @param projectId   owning project identity
     * @param enabled     enabled filter, or null
     * @param environment environment filter, or null
     * @return the matching count
     */
    @Override
    public long countByProject(ProjectId projectId, Boolean enabled, String environment) {
        WhereClause where = buildWhere(projectId, enabled, environment);
        JdbcClient.StatementSpec spec = jdbc.sql(
                "SELECT count(*) FROM feature_toggle ft" + where.sql);
        for (Object param : where.params) {
            spec = spec.param(param);
        }
        return spec.query(Long.class).single();
    }

    /**
     * Deletes a toggle by identity.
     *
     * @param id the toggle identity
     */
    @Override
    public void deleteById(FeatureToggleId id) {
        jdbc.sql("DELETE FROM feature_toggle WHERE id = ?")
                .param(id.value)
                .update();
    }

    private void upsertToggle(FeatureToggle t) {
        try {
            jdbc.sql("""
                    INSERT INTO feature_toggle (id, project_id, name, description, enabled, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (id) DO UPDATE
                        SET name = EXCLUDED.name,
                            description = EXCLUDED.description,
                            enabled = EXCLUDED.enabled,
                            updated_at = EXCLUDED.updated_at
                    """)
                    .param(t.id.value)
                    .param(t.projectId.value)
                    .param(t.name())
                    .param(t.description().orElse(null))
                    .param(t.isEnabled())
                    .param(Timestamp.from(t.createdAt))
                    .param(t.lastModifiedAt().map(Timestamp::from).orElse(null))
                    .update();
        } catch (DuplicateKeyException e) {
            throw new AlreadyExistsException("Toggle", t.name());
        }
    }

    private void syncEnvironments(FeatureToggle t) {
        jdbc.sql("DELETE FROM toggle_environment WHERE toggle_id = ?")
                .param(t.id.value)
                .update();
        String[] envNames = t.environments().toArray(String[]::new);
        jdbc.sql("""
                INSERT INTO toggle_environment (toggle_id, environment_id)
                SELECT ?, e.id FROM environment e WHERE e.name = ANY(?)
                """)
                .param(t.id.value)
                .param(envNames)
                .update();
    }

    private WhereClause buildWhere(ProjectId projectId, Boolean enabled, String environment) {
        StringBuilder sql = new StringBuilder(" WHERE ft.project_id = ?");
        List<Object> params = new ArrayList<>();
        params.add(projectId.value);
        if (enabled != null) {
            sql.append(" AND ft.enabled = ?");
            params.add(enabled);
        }
        if (environment != null) {
            sql.append(" AND ft.id IN (SELECT te.toggle_id FROM toggle_environment te "
                    + "JOIN environment e ON e.id = te.environment_id WHERE e.name = ?)");
            params.add(environment);
        }
        return new WhereClause(sql.toString(), params);
    }

    private record WhereClause(String sql, List<Object> params) {}

    private FeatureToggle mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new FeatureToggle(
                new FeatureToggleId(rs.getObject("id", UUID.class)),
                new ProjectId(rs.getObject("project_id", UUID.class)),
                rs.getString("name"),
                rs.getString("description"),
                rs.getBoolean("enabled"),
                parseEnvironments(rs.getArray("environments")),
                rs.getTimestamp("created_at").toInstant(),
                toInstantOrNull(rs, "updated_at")
        );
    }

    private Set<String> parseEnvironments(Array sqlArray) throws SQLException {
        if (sqlArray == null) {
            return Set.of();
        }
        String[] values = (String[]) sqlArray.getArray();
        return new LinkedHashSet<>(Arrays.asList(values));
    }

    private Instant toInstantOrNull(ResultSet rs, String column) throws SQLException {
        Timestamp ts = rs.getTimestamp(column);
        return ts != null ? ts.toInstant() : null;
    }
}
