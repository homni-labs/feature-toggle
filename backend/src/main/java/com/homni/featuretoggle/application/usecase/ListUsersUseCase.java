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

/**
 * Lists platform users with pagination.
 */
public final class ListUsersUseCase {

    private final AppUserRepositoryPort users;

    /**
     * @param users user persistence port
     */
    public ListUsersUseCase(AppUserRepositoryPort users) {
        this.users = users;
    }

    /**
     * Lists all platform users with pagination.
     *
     * @param page zero-based page number
     * @param size page size
     * @return a page of users
     */
    public UserPage execute(int page, int size) {
        int offset = page * size;
        return new UserPage(users.findAll(offset, size), users.count());
    }
}
