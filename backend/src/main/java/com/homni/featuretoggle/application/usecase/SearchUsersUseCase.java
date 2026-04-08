/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.AppUserRepositoryPort;
import com.homni.featuretoggle.domain.model.AppUser;

import java.util.List;

/**
 * Searches users by email or name substring.
 */
public final class SearchUsersUseCase {

    private static final int MAX_RESULTS = 20;

    private final AppUserRepositoryPort users;

    /**
     * @param users user persistence port
     */
    public SearchUsersUseCase(AppUserRepositoryPort users) {
        this.users = users;
    }

    /**
     * Searches users by email or name (case-insensitive).
     *
     * @param query search query
     * @return up to 20 matching users
     */
    public List<AppUser> execute(String query) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        return users.search(query.trim(), MAX_RESULTS);
    }
}
