/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.outbound.persistence;

import com.homni.togli.application.port.out.AppUserRepositoryPort;
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.Email;
import com.homni.togli.domain.model.PlatformRole;
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
 * JDBC adapter for persisting {@link AppUser} aggregates.
 */
@Repository
public class AppUserJdbcAdapter implements AppUserRepositoryPort {

    private static final Logger log = LoggerFactory.getLogger(AppUserJdbcAdapter.class);

    private static final String COLUMNS =
            "id, oidc_subject, email, name, platform_role, active, created_at, updated_at";

    private final JdbcClient jdbc;

    AppUserJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /** {@inheritDoc} */
    @Override
    public void save(AppUser u) {
        log.debug("Persisting user: id={}, email={}", u.id.value, u.email.value());
        try {
            jdbc.sql("""
                    INSERT INTO app_user (id, oidc_subject, email, name, platform_role, active, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (id) DO UPDATE
                        SET oidc_subject = EXCLUDED.oidc_subject,
                            name = EXCLUDED.name,
                            platform_role = EXCLUDED.platform_role,
                            active = EXCLUDED.active,
                            updated_at = EXCLUDED.updated_at
                    """)
                    .param(u.id.value)
                    .param(u.oidcSubject().orElse(null))
                    .param(u.email.value())
                    .param(u.displayName().orElse(null))
                    .param(u.platformRole().name())
                    .param(u.isActive())
                    .param(Timestamp.from(u.createdAt))
                    .param(u.lastModifiedAt().map(Timestamp::from).orElse(null))
                    .update();
        } catch (DuplicateKeyException e) {
            throw new AlreadyExistsException("User", u.email.value());
        }
    }

    /** {@inheritDoc} */
    @Override
    public Optional<AppUser> findById(UserId id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM app_user WHERE id = ?")
                .param(id.value)
                .query(this::mapRow)
                .optional();
    }

    /** {@inheritDoc} */
    @Override
    public Optional<AppUser> findByOidcSubject(String oidcSubject) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM app_user WHERE oidc_subject = ?")
                .param(oidcSubject)
                .query(this::mapRow)
                .optional();
    }

    /** {@inheritDoc} */
    @Override
    public Optional<AppUser> findByEmail(String email) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM app_user WHERE email = ?")
                .param(email)
                .query(this::mapRow)
                .optional();
    }

    /** {@inheritDoc} */
    @Override
    public List<AppUser> findAll(int offset, int limit) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM app_user ORDER BY email LIMIT ? OFFSET ?")
                .param(limit)
                .param(offset)
                .query(this::mapRow)
                .list();
    }

    /** {@inheritDoc} */
    @Override
    public List<AppUser> search(String query, int limit) {
        String pattern = "%" + query.toLowerCase() + "%";
        return jdbc.sql("SELECT " + COLUMNS
                + " FROM app_user WHERE LOWER(email) LIKE ? OR LOWER(name) LIKE ? ORDER BY email LIMIT ?")
                .param(pattern)
                .param(pattern)
                .param(limit)
                .query(this::mapRow)
                .list();
    }

    /** {@inheritDoc} */
    @Override
    public long count() {
        return jdbc.sql("SELECT count(*) FROM app_user")
                .query(Long.class)
                .single();
    }

    /** {@inheritDoc} */
    @Override
    public void deleteById(UserId id) {
        jdbc.sql("DELETE FROM app_user WHERE id = ?")
                .param(id.value)
                .update();
    }

    private AppUser mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new AppUser(
                new UserId(rs.getObject("id", UUID.class)),
                rs.getString("oidc_subject"),
                new Email(rs.getString("email")),
                rs.getString("name"),
                PlatformRole.valueOf(rs.getString("platform_role")),
                rs.getBoolean("active"),
                rs.getTimestamp("created_at").toInstant(),
                toInstantOrNull(rs, "updated_at")
        );
    }

    private Instant toInstantOrNull(ResultSet rs, String column) throws SQLException {
        Timestamp ts = rs.getTimestamp(column);
        return ts != null ? ts.toInstant() : null;
    }
}
