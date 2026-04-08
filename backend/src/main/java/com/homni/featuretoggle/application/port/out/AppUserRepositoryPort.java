/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.port.out;

import com.homni.featuretoggle.domain.model.AppUser;
import com.homni.featuretoggle.domain.model.UserId;

import java.util.List;
import java.util.Optional;

/**
 * Output port for persisting platform users.
 */
public interface AppUserRepositoryPort {

    /**
     * Saves a user (insert or update).
     *
     * @param user the user to save
     */
    void save(AppUser user);

    /**
     * Finds a user by identity.
     *
     * @param id the user identity
     * @return the user if found, or empty
     */
    Optional<AppUser> findById(UserId id);

    /**
     * Finds a user by OIDC subject.
     *
     * @param oidcSubject the OIDC subject identifier
     * @return the user if found, or empty
     */
    Optional<AppUser> findByOidcSubject(String oidcSubject);

    /**
     * Finds a user by email address.
     *
     * @param email the email address
     * @return the user if found, or empty
     */
    Optional<AppUser> findByEmail(String email);

    /**
     * Lists users with pagination.
     *
     * @param offset rows to skip
     * @param limit  max rows to return
     * @return the matching users
     */
    List<AppUser> findAll(int offset, int limit);

    /**
     * Searches users by email or name substring.
     *
     * @param query  the search query
     * @param limit  max results to return
     * @return the matching users
     */
    List<AppUser> search(String query, int limit);

    /**
     * Counts all users.
     *
     * @return total user count
     */
    long count();

    /**
     * Deletes a user by identity.
     *
     * @param id the user identity
     */
    void deleteById(UserId id);
}
