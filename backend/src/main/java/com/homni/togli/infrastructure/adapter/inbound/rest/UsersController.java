/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.inbound.rest;

import com.homni.togli.application.usecase.GetCurrentUserUseCase;
import com.homni.togli.application.usecase.ListUsersUseCase;
import com.homni.togli.application.usecase.SearchUsersUseCase;
import com.homni.togli.application.usecase.UpdateUserUseCase;
import com.homni.togli.application.usecase.UserPage;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformRole;
import com.homni.togli.domain.model.UserId;
import com.homni.togli.infrastructure.adapter.inbound.rest.presenter.UserPresenter;
import com.homni.generated.api.UsersApi;
import com.homni.generated.model.UpdateUserRequest;
import com.homni.generated.model.UserListResponse;
import com.homni.generated.model.UserSingleResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Handles platform user administration operations.
 */
@RestController
class UsersController implements UsersApi {

    private final GetCurrentUserUseCase getCurrentUser;
    private final ListUsersUseCase listUsers;
    private final SearchUsersUseCase searchUsers;
    private final UpdateUserUseCase updateUser;
    private final UserPresenter presenter;

    /**
     * Creates the users controller.
     *
     * @param getCurrentUser the use case for retrieving the authenticated user
     * @param listUsers      the use case for listing all users
     * @param searchUsers    the use case for searching users
     * @param updateUser     the use case for updating a user
     * @param presenter      maps domain objects to API response models
     */
    UsersController(GetCurrentUserUseCase getCurrentUser,
                    ListUsersUseCase listUsers,
                    SearchUsersUseCase searchUsers,
                    UpdateUserUseCase updateUser,
                    UserPresenter presenter) {
        this.getCurrentUser = getCurrentUser;
        this.listUsers = listUsers;
        this.searchUsers = searchUsers;
        this.updateUser = updateUser;
        this.presenter = presenter;
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<UserSingleResponse> getCurrentUser() {
        return ResponseEntity.ok(presenter.single(getCurrentUser.execute()));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<UserListResponse> listUsers(Integer page, Integer size) {
        PaginationParams p = PaginationParams.of(page, size);
        UserPage result = listUsers.execute(p.page(), p.size());
        return ResponseEntity.ok(presenter.page(result, p.page(), p.size()));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<UserListResponse> searchUsers(String q) {
        List<AppUser> results = searchUsers.execute(q);
        return ResponseEntity.ok(presenter.list(results));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<UserSingleResponse> updateUser(UUID userId, UpdateUserRequest req) {
        PlatformRole role = req.getPlatformRole() != null
                ? PlatformRole.valueOf(req.getPlatformRole().getValue()) : null;
        AppUser user = updateUser.execute(new UserId(userId), role, req.getActive());
        return ResponseEntity.ok(presenter.single(user));
    }
}
