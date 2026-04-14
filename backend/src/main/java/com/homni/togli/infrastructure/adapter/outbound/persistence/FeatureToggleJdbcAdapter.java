/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.outbound.persistence;

import com.homni.togli.application.port.out.FeatureToggleRepositoryPort;
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.FeatureToggleId;
import com.homni.togli.domain.model.ProjectId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * JDBC adapter for persisting {@link FeatureToggle} aggregates scoped to a project.
 */
@Repository
public class FeatureToggleJdbcAdapter implements FeatureToggleRepositoryPort {

    private static final Logger log = LoggerFactory.getLogger(FeatureToggleJdbcAdapter.class);

    /**
     * Selects toggles together with two parallel arrays — env names and the
     * matching enabled flags. Both arrays are ordered by env name so they can
     * be zipped into a {@link Map} on the Java side without any extra
     * bookkeeping.
     */
    private static final String SELECT_WITH_ENVS = """
            SELECT ft.id, ft.project_id, ft.name, ft.description, ft.created_at, ft.updated_at,
                   (SELECT COALESCE(array_agg(e.name ORDER BY e.name), '{}')
                    FROM toggle_environment te
                    JOIN environment e ON e.id = te.environment_id
                    WHERE te.toggle_id = ft.id) AS env_names,
                   (SELECT COALESCE(array_agg(te.enabled ORDER BY e.name), '{}')
                    FROM toggle_environment te
                    JOIN environment e ON e.id = te.environment_id
                    WHERE te.toggle_id = ft.id) AS env_states
            FROM feature_toggle ft""";

    private final JdbcClient jdbc;

    FeatureToggleJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Saves a toggle via upsert and syncs the per-environment state map. The
     * sync uses an UPSERT into {@code toggle_environment}, then deletes any
     * rows whose env was removed from the toggle. Existing per-env states are
     * preserved across updates.
     *
     * @param t the toggle to save
     */
    @Override
    @Transactional
    public void save(FeatureToggle t) {
        log.debug("Persisting toggle: id={}, project={}", t.id.value, t.projectId.value);
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
        log.debug("Deleting toggle: id={}", id.value);
        jdbc.sql("DELETE FROM feature_toggle WHERE id = ?")
                .param(id.value)
                .update();
    }

    /**
     * Disables every (toggle, env) pair in the project that is currently
     * enabled, in a single SQL update. Used when archiving a project so the
     * archived state never has any live flags.
     *
     * @param projectId the owning project identity
     * @return number of (toggle, env) pairs that were disabled
     */
    @Override
    public int disableAllByProject(ProjectId projectId) {
        log.debug("Disabling all toggles for project: id={}", projectId.value);
        return jdbc.sql("""
                UPDATE toggle_environment te
                   SET enabled = false
                  FROM feature_toggle ft
                 WHERE te.toggle_id = ft.id
                   AND ft.project_id = ?
                   AND te.enabled = true
                """)
                .param(projectId.value)
                .update();
    }

    private void upsertToggle(FeatureToggle t) {
        try {
            jdbc.sql("""
                    INSERT INTO feature_toggle (id, project_id, name, description, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                    ON CONFLICT (id) DO UPDATE
                        SET name = EXCLUDED.name,
                            description = EXCLUDED.description,
                            updated_at = EXCLUDED.updated_at
                    """)
                    .param(t.id.value)
                    .param(t.projectId.value)
                    .param(t.name())
                    .param(t.description().orElse(null))
                    .param(Timestamp.from(t.createdAt))
                    .param(t.lastModifiedAt().map(Timestamp::from).orElse(null))
                    .update();
        } catch (DuplicateKeyException e) {
            throw new AlreadyExistsException("Toggle", t.name());
        }
    }

    /**
     * Wipe-and-replace sync of the join table with the toggle's current
     * per-env state map. Two flat statements:
     * <ol>
     *   <li>DELETE every existing row for this toggle.</li>
     *   <li>INSERT one row per (env name, enabled) pair from the desired map,
     *       resolving env_id by JOIN on the project's {@code environment} table.</li>
     * </ol>
     * Atomicity is inherited from the {@code @Transactional} parent
     * {@link #save}: both statements share its transaction, so other readers
     * never observe the intermediate "everything deleted, nothing inserted"
     * state under Postgres' default read-committed isolation. Domain
     * validation in {@link FeatureToggle} guarantees every name in the map
     * resolves to a row in {@code environment}, so the INSERT JOIN never
     * silently drops rows.
     */
    private void syncEnvironments(FeatureToggle t) {
        jdbc.sql("DELETE FROM toggle_environment WHERE toggle_id = ?")
                .param(t.id.value)
                .update();

        Map<String, Boolean> states = t.environmentStates();
        if (states.isEmpty()) {
            return;
        }
        log.debug("Syncing toggle environments: id={}, envCount={}", t.id.value, states.size());
        String[] envNames = new String[states.size()];
        Boolean[] envEnabled = new Boolean[states.size()];
        int i = 0;
        for (Map.Entry<String, Boolean> entry : states.entrySet()) {
            envNames[i] = entry.getKey();
            envEnabled[i++] = entry.getValue();
        }

        jdbc.sql("""
                INSERT INTO toggle_environment (toggle_id, environment_id, enabled)
                SELECT ?, e.id, vals.enabled
                  FROM unnest(?::text[], ?::boolean[]) AS vals(name, enabled)
                  JOIN environment e
                    ON e.project_id = ?
                   AND e.name = vals.name
                """)
                .param(t.id.value)
                .param(envNames)
                .param(envEnabled)
                .param(t.projectId.value)
                .update();
    }

    private WhereClause buildWhere(ProjectId projectId, Boolean enabled, String environment) {
        StringBuilder sql = new StringBuilder(" WHERE ft.project_id = ?");
        List<Object> params = new ArrayList<>();
        params.add(projectId.value);

        // No env-state filters → just project scope.
        if (enabled == null && environment == null) {
            return new WhereClause(sql.toString(), params);
        }

        // Single EXISTS scaffold; filter sub-clauses are appended à la carte.
        // Adding a new filter later means one extra `if` instead of doubling
        // the number of branches.
        sql.append(" AND EXISTS (SELECT 1 FROM toggle_environment te"
                + " JOIN environment e ON e.id = te.environment_id"
                + " WHERE te.toggle_id = ft.id");
        if (enabled != null) {
            sql.append(" AND te.enabled = ?");
            params.add(enabled);
        }
        if (environment != null) {
            sql.append(" AND e.name = ?");
            params.add(environment);
        }
        sql.append(")");

        return new WhereClause(sql.toString(), params);
    }

    private record WhereClause(String sql, List<Object> params) {}

    private FeatureToggle mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new FeatureToggle(
                new FeatureToggleId(rs.getObject("id", UUID.class)),
                new ProjectId(rs.getObject("project_id", UUID.class)),
                rs.getString("name"),
                rs.getString("description"),
                zipEnvironmentStates(rs.getArray("env_names"), rs.getArray("env_states")),
                rs.getTimestamp("created_at").toInstant(),
                toInstantOrNull(rs, "updated_at")
        );
    }

    /**
     * Zips two parallel SQL arrays (names and matching booleans) into a
     * {@link Map}. Returns an empty map if either array is null/empty. The
     * returned map's iteration order is unspecified — anything that needs a
     * stable order (e.g. the API presenter) is expected to sort explicitly.
     */
    private Map<String, Boolean> zipEnvironmentStates(Array nameArray, Array stateArray) throws SQLException {
        if (nameArray == null || stateArray == null) {
            return Map.of();
        }
        String[] names = (String[]) nameArray.getArray();
        Boolean[] states = (Boolean[]) stateArray.getArray();
        if (names.length != states.length) {
            throw new IllegalStateException(
                    "Toggle env_names/env_states arrays length mismatch: %d vs %d"
                            .formatted(names.length, states.length));
        }
        HashMap<String, Boolean> result = new HashMap<>(names.length);
        for (int i = 0; i < names.length; i++) {
            result.put(names[i], Boolean.TRUE.equals(states[i]));
        }
        return result;
    }

    private Instant toInstantOrNull(ResultSet rs, String column) throws SQLException {
        Timestamp ts = rs.getTimestamp(column);
        return ts != null ? ts.toInstant() : null;
    }
}
