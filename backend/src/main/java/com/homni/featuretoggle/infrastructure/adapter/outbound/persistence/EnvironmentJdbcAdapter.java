/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.outbound.persistence;

import com.homni.featuretoggle.application.port.out.EnvironmentRepositoryPort;
import com.homni.featuretoggle.domain.exception.AlreadyExistsException;
import com.homni.featuretoggle.domain.model.Environment;
import com.homni.featuretoggle.domain.model.EnvironmentId;
import com.homni.featuretoggle.domain.model.ProjectId;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * JDBC adapter for persisting {@link Environment} aggregates.
 */
@Repository
public class EnvironmentJdbcAdapter implements EnvironmentRepositoryPort {

    private static final String COLUMNS = "id, project_id, name, created_at";

    private final JdbcClient jdbc;
    private final JdbcTemplate jdbcTemplate;

    EnvironmentJdbcAdapter(JdbcClient jdbc, JdbcTemplate jdbcTemplate) {
        this.jdbc = jdbc;
        this.jdbcTemplate = jdbcTemplate;
    }

    /** {@inheritDoc} */
    @Override
    public void save(Environment env) {
        try {
            jdbc.sql("""
                    INSERT INTO environment (id, project_id, name, created_at)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT (id) DO UPDATE
                        SET name = EXCLUDED.name
                    """)
                    .param(env.id.value)
                    .param(env.projectId.value)
                    .param(env.name())
                    .param(Timestamp.from(env.createdAt))
                    .update();
        } catch (DuplicateKeyException e) {
            throw new AlreadyExistsException("Environment", env.name());
        }
    }

    /**
     * Persists a batch of environments in a single JDBC batch (one prepared
     * statement, one round-trip), wrapped in a transaction so the caller
     * never sees a partially-bootstrapped project.
     *
     * @param environments environments to save
     */
    @Override
    @Transactional
    public void saveAll(List<Environment> environments) {
        if (environments.isEmpty()) {
            return;
        }
        List<Object[]> batchArgs = new ArrayList<>(environments.size());
        for (Environment env : environments) {
            batchArgs.add(new Object[] {
                    env.id.value,
                    env.projectId.value,
                    env.name(),
                    Timestamp.from(env.createdAt)
            });
        }
        try {
            jdbcTemplate.batchUpdate("""
                    INSERT INTO environment (id, project_id, name, created_at)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT (id) DO UPDATE
                        SET name = EXCLUDED.name
                    """, batchArgs);
        } catch (DuplicateKeyException e) {
            throw new AlreadyExistsException("Environment", environments.get(0).name());
        }
    }

    /** {@inheritDoc} */
    @Override
    public Optional<Environment> findById(EnvironmentId id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM environment WHERE id = ?")
                .param(id.value)
                .query(this::mapRow)
                .optional();
    }

    /** {@inheritDoc} */
    @Override
    public List<Environment> findAllByProject(ProjectId projectId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM environment WHERE project_id = ? ORDER BY name")
                .param(projectId.value)
                .query(this::mapRow)
                .list();
    }

    /** {@inheritDoc} */
    @Override
    public Set<String> findNamesByProjectId(ProjectId projectId) {
        List<String> names = jdbc.sql("SELECT name FROM environment WHERE project_id = ?")
                .param(projectId.value)
                .query((rs, rowNum) -> rs.getString("name"))
                .list();
        return new LinkedHashSet<>(names);
    }

    /** {@inheritDoc} */
    @Override
    public void deleteById(EnvironmentId id) {
        jdbc.sql("DELETE FROM environment WHERE id = ?")
                .param(id.value)
                .update();
    }

    /** {@inheritDoc} */
    @Override
    public boolean isEnvironmentInUse(String name, ProjectId projectId) {
        return jdbc.sql("""
                SELECT EXISTS(
                    SELECT 1 FROM toggle_environment te
                    JOIN environment e ON e.id = te.environment_id
                    WHERE e.name = ? AND e.project_id = ?)
                """)
                .param(name)
                .param(projectId.value)
                .query(Boolean.class)
                .single();
    }

    private Environment mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new Environment(
                new EnvironmentId(rs.getObject("id", UUID.class)),
                new ProjectId(rs.getObject("project_id", UUID.class)),
                rs.getString("name"),
                rs.getTimestamp("created_at").toInstant()
        );
    }
}
