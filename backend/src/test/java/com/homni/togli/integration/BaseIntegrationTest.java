/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.integration;

import com.homni.togli.SharedTestContainer;
import com.homni.togli.application.port.out.CallerPort;
import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformAdminAccess;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.ProjectSlug;
import com.homni.togli.domain.model.RoleBasedAccess;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Base class for integration tests that use a real PostgreSQL database
 * via Testcontainers.
 *
 * <p>The container is started once via {@link SharedTestContainer} and
 * shared across all test classes. Spring context is cached and shared
 * across all subclasses.
 *
 * <p>Two infrastructure ports ({@link CallerPort} and {@link CallerProjectAccessPort})
 * are mocked since they depend on Spring Security context.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@ActiveProfiles("test")
abstract class BaseIntegrationTest {

    @MockitoBean
    CallerPort callerPort;

    @MockitoBean
    CallerProjectAccessPort callerProjectAccessPort;

    @DynamicPropertySource
    static void configureDatabase(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", SharedTestContainer.PG::getJdbcUrl);
        registry.add("spring.datasource.username", SharedTestContainer.PG::getUsername);
        registry.add("spring.datasource.password", SharedTestContainer.PG::getPassword);
    }

    /**
     * Sets the caller to a platform admin.
     */
    protected void actAsAdmin(AppUser admin) {
        when(callerPort.get()).thenReturn(admin);
        when(callerProjectAccessPort.resolve(any(ProjectId.class)))
                .thenReturn(new PlatformAdminAccess());
    }

    /**
     * Sets the caller to a project member with a specific role.
     */
    protected void actAsMember(AppUser user, ProjectId projectId, ProjectRole role) {
        when(callerPort.get()).thenReturn(user);
        when(callerProjectAccessPort.resolve(projectId))
                .thenReturn(new RoleBasedAccess(projectId, role));
    }

    protected static AppUser adminUser() {
        AppUser user = new AppUser("oidc-" + UUID.randomUUID(), "admin-" + UUID.randomUUID().toString().substring(0, 6) + "@test.com", "Test Admin");
        user.promoteToPlatformAdmin();
        return user;
    }

    protected static AppUser regularUser() {
        return new AppUser("oidc-" + UUID.randomUUID(), "user-" + UUID.randomUUID().toString().substring(0, 6) + "@test.com", "Test User");
    }

    protected static ProjectSlug randomSlug() {
        return new ProjectSlug("PRJ-" + randomSuffix());
    }

    protected static String randomSuffix() {
        return UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
