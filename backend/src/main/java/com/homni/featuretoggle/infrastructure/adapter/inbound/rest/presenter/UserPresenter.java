/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.inbound.rest.presenter;

import com.homni.featuretoggle.application.usecase.UserPage;
import com.homni.featuretoggle.domain.model.AppUser;
import com.homni.generated.model.Pagination;
import com.homni.generated.model.ResponseMeta;
import com.homni.generated.model.UserListResponse;
import com.homni.generated.model.UserSingleResponse;
import org.openapitools.jackson.nullable.JsonNullable;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Maps user domain objects to generated OpenAPI response models.
 */
@Component
public class UserPresenter {

    /**
     * Wraps a single user in a typed response envelope.
     *
     * @param user the domain user
     * @return the typed single response
     */
    public UserSingleResponse single(AppUser user) {
        return new UserSingleResponse(toDto(user), meta());
    }

    /**
     * Wraps a page of users in a typed response envelope.
     *
     * @param page     the domain user page
     * @param pageNum  zero-based page number
     * @param pageSize page size
     * @return the typed list response with pagination
     */
    public UserListResponse page(UserPage page, int pageNum, int pageSize) {
        List<com.homni.generated.model.User> items = page.items().stream()
                .map(this::toDto).toList();
        return new UserListResponse(
                items, pagination(page.totalElements(), pageNum, pageSize), meta());
    }

    /**
     * Wraps a flat list of users (search results) in a typed response envelope.
     *
     * @param users the domain user list
     * @return the typed list response with no pagination
     */
    public UserListResponse list(List<AppUser> users) {
        List<com.homni.generated.model.User> items = users.stream()
                .map(this::toDto).toList();
        return new UserListResponse(items, null, meta());
    }

    private com.homni.generated.model.User toDto(AppUser u) {
        com.homni.generated.model.User dto = new com.homni.generated.model.User(
                u.id.value, u.email.value(),
                com.homni.generated.model.User.PlatformRoleEnum.fromValue(u.platformRole().name()),
                u.isActive(), toUtc(u.createdAt));
        dto.setOidcSubject(u.oidcSubject().orElse(null));
        dto.setName(u.displayName().orElse(null));
        u.lastModifiedAt().ifPresent(t -> dto.setUpdatedAt(JsonNullable.of(toUtc(t))));
        return dto;
    }

    private Pagination pagination(long totalElements, int pageNum, int pageSize) {
        int totalPages = pageSize > 0 ? (int) Math.ceil((double) totalElements / pageSize) : 0;
        return new Pagination(pageNum, pageSize, totalElements, totalPages);
    }

    private ResponseMeta meta() {
        return new ResponseMeta(OffsetDateTime.now(ZoneOffset.UTC));
    }

    private OffsetDateTime toUtc(Instant instant) {
        return instant != null ? instant.atOffset(ZoneOffset.UTC) : null;
    }
}
