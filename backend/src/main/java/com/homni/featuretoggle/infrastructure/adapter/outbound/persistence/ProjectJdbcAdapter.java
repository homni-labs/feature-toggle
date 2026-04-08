/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.outbound.persistence;

import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.exception.AlreadyExistsException;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.ProjectSlug;
import com.homni.featuretoggle.application.usecase.ProjectWithRole;
import com.homni.featuretoggle.domain.model.ProjectRole;
import com.homni.featuretoggle.domain.model.UserId;
import org.springframework.dao.DuplicateKeyException;
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
 * JDBC adapter for persisting {@link Project} aggregates.
 */
@Repository
public class ProjectJdbcAdapter implements ProjectRepositoryPort {

    private static final String COLUMNS =
            "id, slug, name, description, archived, created_at, updated_at";

    private final JdbcClient jdbc;

    ProjectJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Saves a project via upsert.
     *
     * @param project the project to save
     * @throws AlreadyExistsException if the project slug already exists
     */
    @Override
    public void save(Project project) {
        try {
            jdbc.sql("""
                    INSERT INTO project (id, slug, name, description, archived, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (id) DO UPDATE
                        SET name = EXCLUDED.name,
                            description = EXCLUDED.description,
                            archived = EXCLUDED.archived,
                            updated_at = EXCLUDED.updated_at
                    """)
                    .param(project.id.value)
                    .param(project.slug.value())
                    .param(project.name())
                    .param(project.description().orElse(null))
                    .param(project.isArchived())
                    .param(Timestamp.from(project.createdAt))
                    .param(project.lastModifiedAt().map(Timestamp::from).orElse(null))
                    .update();
        } catch (DuplicateKeyException e) {
            throw new AlreadyExistsException("Project", project.slug.value());
        }
    }

    /**
     * Finds a project by identity.
     *
     * @param id the project identity
     * @return the project, or empty
     */
    @Override
    public Optional<Project> findById(ProjectId id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM project WHERE id = ?")
                .param(id.value)
                .query(this::mapRow)
                .optional();
    }

    /**
     * Returns all projects ordered by name.
     *
     * @return all projects
     */
    @Override
    public List<Project> findAll() {
        return jdbc.sql("SELECT " + COLUMNS + " FROM project ORDER BY name")
                .query(this::mapRow)
                .list();
    }

    /**
     * Returns non-archived projects the user belongs to.
     *
     * @param userId the user identity
     * @return the user's projects
     */
    @Override
    public List<Project> findByMember(UserId userId) {
        return jdbc.sql("""
                SELECT p.id, p.slug, p.name, p.description, p.archived, p.created_at, p.updated_at
                FROM project p
                JOIN project_membership pm ON pm.project_id = p.id
                WHERE pm.user_id = ? AND p.archived = false
                ORDER BY p.name
                """)
                .param(userId.value)
                .query(this::mapRow)
                .list();
    }

    /**
     * Returns non-archived projects with the user's role.
     *
     * @param userId the user identity
     * @return the projects with role
     */
    @Override
    public List<ProjectWithRole> findByMemberWithRole(UserId userId) {
        return jdbc.sql("""
                SELECT p.id, p.slug, p.name, p.description, p.archived, p.created_at, p.updated_at,
                       pm.role AS my_role
                FROM project p
                JOIN project_membership pm ON pm.project_id = p.id
                WHERE pm.user_id = ? AND p.archived = false
                ORDER BY p.name
                """)
                .param(userId.value)
                .query(this::mapRowWithRole)
                .list();
    }

    private Project mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new Project(
                new ProjectId(rs.getObject("id", UUID.class)),
                new ProjectSlug(rs.getString("slug")),
                rs.getString("name"),
                rs.getString("description"),
                rs.getBoolean("archived"),
                rs.getTimestamp("created_at").toInstant(),
                toInstantOrNull(rs, "updated_at")
        );
    }

    private ProjectWithRole mapRowWithRole(ResultSet rs, int rowNum) throws SQLException {
        Project project = mapRow(rs, rowNum);
        return new ProjectWithRole(project, ProjectRole.valueOf(rs.getString("my_role")));
    }

    private Instant toInstantOrNull(ResultSet rs, String column) throws SQLException {
        Timestamp ts = rs.getTimestamp(column);
        return ts != null ? ts.toInstant() : null;
    }
}
