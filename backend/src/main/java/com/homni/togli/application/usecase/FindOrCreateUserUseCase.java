/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.AppUserRepositoryPort;
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformRole;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Optional;

/**
 * Finds a user by OIDC subject, or binds/creates one on first login.
 */
public final class FindOrCreateUserUseCase {

    private static final Logger log = LoggerFactory.getLogger(FindOrCreateUserUseCase.class);

    private final AppUserRepositoryPort users;
    private final String defaultAdminEmail;

    /**
     * @param users             user persistence port
     * @param defaultAdminEmail default admin email address
     */
    public FindOrCreateUserUseCase(AppUserRepositoryPort users, String defaultAdminEmail) {
        this.users = users;
        this.defaultAdminEmail = defaultAdminEmail;
    }

    /**
     * Resolves or creates a user for the OIDC subject.
     *
     * @param oidcSubject OIDC subject identifier
     * @param email       user's email address
     * @param name        display name, may be {@code null}
     * @return the resolved or created user
     * @throws com.homni.togli.domain.exception.DomainValidationException if the email is invalid
     */
    public AppUser execute(String oidcSubject, String email, String name) {
        log.debug("Resolving user: oidcSubject={}, email={}", oidcSubject, email);
        AppUser user = resolveUser(oidcSubject, email, name);
        bootstrapDefaultAdmin(user);
        return user;
    }

    private AppUser resolveUser(String oidcSubject, String email, String name) {
        try {
            return findBySubjectOrBindOrCreate(oidcSubject, email, name);
        } catch (AlreadyExistsException ignored) {
            return users.findByOidcSubject(oidcSubject)
                    .orElseGet(() -> users.findByEmail(email).orElseThrow(() -> ignored));
        }
    }

    private AppUser findBySubjectOrBindOrCreate(String oidcSubject, String email, String name) {
        Optional<AppUser> bySubject = users.findByOidcSubject(oidcSubject);
        if (bySubject.isPresent()) {
            log.debug("User found by OIDC subject: id={}", bySubject.get().id.value);
            return bySubject.get();
        }
        return tryBindOrCreate(oidcSubject, email, name);
    }

    private AppUser tryBindOrCreate(String oidcSubject, String email, String name) {
        Optional<AppUser> byEmail = users.findByEmail(email);
        if (byEmail.isPresent() && byEmail.get().canBindOidc()) {
            AppUser existing = byEmail.get();
            log.debug("Binding OIDC subject to existing user: id={}, email={}", existing.id.value, email);
            existing.bindOidcSubject(oidcSubject);
            users.save(existing);
            return existing;
        }
        log.debug("Creating new user: email={}", email);
        AppUser newUser = new AppUser(oidcSubject, email, name);
        users.save(newUser);
        return newUser;
    }

    private void bootstrapDefaultAdmin(AppUser user) {
        if (isDefaultAdmin(user) && user.platformRole() == PlatformRole.USER) {
            log.debug("Bootstrapping default admin: id={}, email={}", user.id.value, user.email.value());
            user.promoteToPlatformAdmin();
            users.save(user);
        }
    }

    private boolean isDefaultAdmin(AppUser user) {
        return defaultAdminEmail != null
                && defaultAdminEmail.equalsIgnoreCase(user.email.value());
    }
}
