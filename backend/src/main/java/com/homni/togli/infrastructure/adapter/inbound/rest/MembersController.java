/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.inbound.rest;

import com.homni.togli.application.usecase.ListMembersUseCase;
import com.homni.togli.application.usecase.MemberPage;
import com.homni.togli.application.usecase.RemoveMemberUseCase;
import com.homni.togli.application.usecase.UpsertMemberUseCase;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.UserId;
import com.homni.togli.infrastructure.adapter.inbound.rest.presenter.MemberPresenter;
import com.homni.generated.api.MembersApi;
import com.homni.generated.model.ChangeMemberRoleRequest;
import com.homni.generated.model.MembershipListResponse;
import com.homni.generated.model.MembershipSingleResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Handles project membership management operations.
 */
@RestController
class MembersController implements MembersApi {

    private final UpsertMemberUseCase upsertMember;
    private final ListMembersUseCase listMembers;
    private final RemoveMemberUseCase removeMember;
    private final MemberPresenter presenter;

    /**
     * Creates the members controller.
     *
     * @param upsertMember the use case for adding or updating a member
     * @param listMembers  the use case for listing members
     * @param removeMember the use case for removing a member
     * @param presenter    maps domain objects to API response models
     */
    MembersController(UpsertMemberUseCase upsertMember,
                      ListMembersUseCase listMembers,
                      RemoveMemberUseCase removeMember,
                      MemberPresenter presenter) {
        this.upsertMember = upsertMember;
        this.listMembers = listMembers;
        this.removeMember = removeMember;
        this.presenter = presenter;
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<MembershipSingleResponse> upsertMember(UUID projectId, UUID userId,
                                                                   ChangeMemberRoleRequest req) {
        ProjectMembership membership = upsertMember.execute(
                new ProjectId(projectId), new UserId(userId),
                ProjectRole.valueOf(req.getRole().getValue()));
        return ResponseEntity.ok(presenter.single(membership));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<MembershipListResponse> listMembers(UUID projectId, Integer page,
                                                               Integer size) {
        PaginationParams p = PaginationParams.of(page, size);
        MemberPage result = listMembers.execute(new ProjectId(projectId), p.page(), p.size());
        return ResponseEntity.ok(presenter.list(result, p.page(), p.size()));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<Void> removeMember(UUID projectId, UUID userId) {
        removeMember.execute(new ProjectId(projectId), new UserId(userId));
        return ResponseEntity.noContent().build();
    }
}
