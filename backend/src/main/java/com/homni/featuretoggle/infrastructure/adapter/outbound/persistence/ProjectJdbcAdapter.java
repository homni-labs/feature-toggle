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
import com.homni.featuretoggle.application.usecase.ProjectListItem;
import com.homni.featuretoggle.domain.exception.AlreadyExistsException;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.ProjectRole;
import com.homni.featuretoggle.domain.model.ProjectSlug;
import com.homni.featuretoggle.domain.model.UserId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * JDBC adapter for persisting {@link Project} aggregates.
 */
@Repository
public class ProjectJdbcAdapter implements ProjectRepositoryPort {

    private static final Logger log = LoggerFactory.getLogger(ProjectJdbcAdapter.class);

    private static final String COLUMNS =
            "id, slug, name, description, archived, created_at, updated_at";

    /**
     * Selects projects together with the caller's role (LEFT JOIN — null when
     * the caller is not a member, e.g. for platform admins) and three
     * subquery-aggregated counters used by the projects screen.
     *
     * <p>The subqueries hit indexed FK columns ({@code idx_toggle_project},
     * {@code uq_environment_project_name}, {@code uq_membership(project_id,
     * user_id)}), so each one is a quick index scan even on workspaces with
     * many projects.
     */
    private static final String SELECT_PAGE_WITH_COUNTS = """
            SELECT p.id, p.slug, p.name, p.description, p.archived, p.created_at, p.updated_at,
                   pm.role AS my_role,
                   (SELECT COUNT(*) FROM feature_toggle    WHERE project_id = p.id) AS toggles_count,
                   (SELECT COUNT(*) FROM environment       WHERE project_id = p.id) AS envs_count,
                   (SELECT COUNT(*) FROM project_membership WHERE project_id = p.id) AS members_count
              FROM project p
              LEFT JOIN project_membership pm
                     ON pm.project_id = p.id AND pm.user_id = ?
            """;

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
        log.debug("Persisting project: id={}, slug={}", project.id.value, project.slug.value());
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

    @Override
    public Optional<Project> findBySlug(ProjectSlug slug) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM project WHERE slug = ?")
                .param(slug.value())
                .query(this::mapRow)
                .optional();
    }

    /**
     * Returns a page of projects visible to the caller with pre-aggregated
     * counters and the caller's role in each project. See the port JavaDoc for
     * the visibility rules and filter semantics.
     *
     * @param callerUserId  the caller's user identity
     * @param platformAdmin whether the caller is a platform admin
     * @param searchText    optional case-insensitive name/slug substring filter
     * @param archived      optional archived filter
     * @param offset        rows to skip
     * @param limit         max rows to return
     * @return matching projects with role + counts, ordered by name
     */
    @Override
    public List<ProjectListItem> findPage(UserId callerUserId, boolean platformAdmin,
                                          String searchText, Boolean archived,
                                          int offset, int limit) {
        WhereClause where = buildWhere(platformAdmin, searchText, archived);
        JdbcClient.StatementSpec spec = jdbc.sql(
                SELECT_PAGE_WITH_COUNTS + where.sql + " ORDER BY p.name LIMIT ? OFFSET ?")
                .param(callerUserId.value);
        for (Object param : where.params) {
            spec = spec.param(param);
        }
        return spec.param(limit).param(offset).query(this::mapPageRow).list();
    }

    /**
     * Counts projects visible to the caller, applying the same visibility
     * rules and filters as {@link #findPage}.
     *
     * @param callerUserId  the caller's user identity
     * @param platformAdmin whether the caller is a platform admin
     * @param searchText    optional case-insensitive name/slug substring filter
     * @param archived      optional archived filter
     * @return matching project count
     */
    @Override
    public long countMatching(UserId callerUserId, boolean platformAdmin,
                              String searchText, Boolean archived) {
        WhereClause where = buildWhere(platformAdmin, searchText, archived);
        // The LEFT JOIN is still needed because the visibility branch for
        // non-PA callers references pm.user_id / pm.role.
        JdbcClient.StatementSpec spec = jdbc.sql("""
                SELECT COUNT(*)
                  FROM project p
                  LEFT JOIN project_membership pm
                         ON pm.project_id = p.id AND pm.user_id = ?
                """ + where.sql)
                .param(callerUserId.value);
        for (Object param : where.params) {
            spec = spec.param(param);
        }
        return spec.query(Long.class).single();
    }

    /**
     * Builds the WHERE clause for {@link #findPage} and {@link #countMatching}.
     * Splits cleanly into a visibility branch (PA vs member) plus optional
     * archived and search filters layered on top.
     *
     * @param platformAdmin whether the caller is a platform admin
     * @param searchText    optional case-insensitive name/slug substring filter
     * @param archived      optional archived filter
     * @return SQL fragment + ordered params
     */
    private WhereClause buildWhere(boolean platformAdmin, String searchText, Boolean archived) {
        StringBuilder sql = new StringBuilder(" WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (!platformAdmin) {
            sql.append(" AND pm.user_id IS NOT NULL")
               .append(" AND (p.archived = false OR pm.role = 'ADMIN')");
        }

        if (archived != null) {
            sql.append(" AND p.archived = ?");
            params.add(archived);
        }

        if (searchText != null && !searchText.isBlank()) {
            sql.append(" AND (LOWER(p.name) LIKE ? OR LOWER(p.slug) LIKE ?)");
            String pattern = "%" + searchText.toLowerCase() + "%";
            params.add(pattern);
            params.add(pattern);
        }

        return new WhereClause(sql.toString(), params);
    }

    private record WhereClause(String sql, List<Object> params) {}

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

    private ProjectListItem mapPageRow(ResultSet rs, int rowNum) throws SQLException {
        Project project = mapRow(rs, rowNum);
        String roleString = rs.getString("my_role");
        ProjectRole myRole = roleString != null ? ProjectRole.valueOf(roleString) : null;
        long togglesCount = rs.getLong("toggles_count");
        long envsCount = rs.getLong("envs_count");
        long membersCount = rs.getLong("members_count");
        return new ProjectListItem(project, myRole, togglesCount, envsCount, membersCount);
    }

    private Instant toInstantOrNull(ResultSet rs, String column) throws SQLException {
        Timestamp ts = rs.getTimestamp(column);
        return ts != null ? ts.toInstant() : null;
    }
}
