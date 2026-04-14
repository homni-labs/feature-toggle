/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.outbound.persistence;

import com.homni.togli.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.togli.domain.model.ProjectMembershipId;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.UserId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
 * JDBC adapter for persisting {@link ProjectMembership} aggregates.
 */
@Repository
public class ProjectMembershipJdbcAdapter implements ProjectMembershipRepositoryPort {

    private static final Logger log = LoggerFactory.getLogger(ProjectMembershipJdbcAdapter.class);

    private static final String COLUMNS =
            "id, project_id, user_id, role, granted_at, updated_at";

    private final JdbcClient jdbc;

    ProjectMembershipJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Saves a membership via upsert.
     *
     * @param membership the membership to save
     * @throws AlreadyExistsException if already a member
     */
    @Override
    public void save(ProjectMembership membership) {
        log.debug("Persisting membership: project={}, user={}, role={}", membership.projectId.value, membership.userId.value, membership.currentRole());
        try {
            jdbc.sql("""
                    INSERT INTO project_membership (id, project_id, user_id, role, granted_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                    ON CONFLICT (id) DO UPDATE
                        SET role = EXCLUDED.role,
                            updated_at = EXCLUDED.updated_at
                    """)
                    .param(membership.id.value)
                    .param(membership.projectId.value)
                    .param(membership.userId.value)
                    .param(membership.currentRole().name())
                    .param(Timestamp.from(membership.grantedAt))
                    .param(membership.lastModifiedAt().map(Timestamp::from).orElse(null))
                    .update();
        } catch (DuplicateKeyException e) {
            throw new AlreadyExistsException("Membership", "project=%s, user=%s".formatted(membership.projectId.value, membership.userId.value));
        }
    }

    /**
     * Finds a membership by project and user.
     *
     * @param projectId the project identity
     * @param userId    the user identity
     * @return the membership, or empty
     */
    @Override
    public Optional<ProjectMembership> findByProjectAndUser(ProjectId projectId, UserId userId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM project_membership WHERE project_id = ? AND user_id = ?")
                .param(projectId.value)
                .param(userId.value)
                .query(this::mapRow)
                .optional();
    }

    /**
     * Lists memberships for a project with pagination.
     *
     * @param projectId the project identity
     * @param offset    rows to skip
     * @param limit     max rows to return
     * @return the project memberships
     */
    @Override
    public List<ProjectMembership> findByProject(ProjectId projectId, int offset, int limit) {
        return jdbc.sql("""
                SELECT pm.id, pm.project_id, pm.user_id, pm.role,
                       pm.granted_at, pm.updated_at,
                       u.email, u.name
                FROM project_membership pm
                JOIN app_user u ON u.id = pm.user_id
                WHERE pm.project_id = ?
                ORDER BY pm.granted_at LIMIT ? OFFSET ?
                """)
                .param(projectId.value)
                .param(limit)
                .param(offset)
                .query(this::mapRowWithUser)
                .list();
    }

    /**
     * Counts memberships for a project.
     *
     * @param projectId the project identity
     * @return the member count
     */
    @Override
    public long countByProject(ProjectId projectId) {
        return jdbc.sql("SELECT count(*) FROM project_membership WHERE project_id = ?")
                .param(projectId.value)
                .query(Long.class)
                .single();
    }

    /**
     * Removes a membership by project and user.
     *
     * @param projectId the project identity
     * @param userId    the user identity
     */
    @Override
    public void deleteByProjectAndUser(ProjectId projectId, UserId userId) {
        log.debug("Deleting membership: project={}, user={}", projectId.value, userId.value);
        jdbc.sql("DELETE FROM project_membership WHERE project_id = ? AND user_id = ?")
                .param(projectId.value)
                .param(userId.value)
                .update();
    }

    private ProjectMembership mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new ProjectMembership(
                new ProjectMembershipId(rs.getObject("id", UUID.class)),
                new ProjectId(rs.getObject("project_id", UUID.class)),
                new UserId(rs.getObject("user_id", UUID.class)),
                ProjectRole.valueOf(rs.getString("role")),
                rs.getTimestamp("granted_at").toInstant(),
                toInstantOrNull(rs, "updated_at")
        );
    }

    private ProjectMembership mapRowWithUser(ResultSet rs, int rowNum) throws SQLException {
        return new ProjectMembership(
                new ProjectMembershipId(rs.getObject("id", UUID.class)),
                new ProjectId(rs.getObject("project_id", UUID.class)),
                new UserId(rs.getObject("user_id", UUID.class)),
                ProjectRole.valueOf(rs.getString("role")),
                rs.getTimestamp("granted_at").toInstant(),
                toInstantOrNull(rs, "updated_at"),
                rs.getString("email"),
                rs.getString("name")
        );
    }

    private Instant toInstantOrNull(ResultSet rs, String column) throws SQLException {
        Timestamp ts = rs.getTimestamp(column);
        return ts != null ? ts.toInstant() : null;
    }
}
