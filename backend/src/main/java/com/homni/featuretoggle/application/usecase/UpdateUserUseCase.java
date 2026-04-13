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
import com.homni.featuretoggle.application.port.out.CallerPort;
import com.homni.featuretoggle.domain.exception.CannotModifySelfException;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.exception.InvalidStateException;
import com.homni.featuretoggle.domain.model.AppUser;
import com.homni.featuretoggle.domain.model.PlatformRole;
import com.homni.featuretoggle.domain.model.UserId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Updates a user's platform role and active status.
 */
public final class UpdateUserUseCase {

    private static final Logger log = LoggerFactory.getLogger(UpdateUserUseCase.class);

    private final AppUserRepositoryPort users;
    private final CallerPort callerPort;

    /**
     * @param users      user persistence port
     * @param callerPort authenticated caller provider
     */
    public UpdateUserUseCase(AppUserRepositoryPort users, CallerPort callerPort) {
        this.users = users;
        this.callerPort = callerPort;
    }

    /**
     * Updates platform role and/or active status.
     *
     * @param targetId  user to update
     * @param newRole   new role, or {@code null} to keep
     * @param newActive new active flag, or {@code null} to keep
     * @return the updated user
     * @throws CannotModifySelfException if the caller modifies themselves
     * @throws EntityNotFoundException if the user does not exist
     * @throws InvalidStateException if the state transition is invalid
     */
    public AppUser execute(UserId targetId, PlatformRole newRole, Boolean newActive) {
        log.debug("Updating user: id={}, newRole={}, newActive={}", targetId.value, newRole, newActive);
        UserId callerId = callerPort.get().id;
        if (targetId.equals(callerId)) {
            throw new CannotModifySelfException(callerId);
        }
        AppUser user = users.findById(targetId)
                .orElseThrow(() -> new EntityNotFoundException("User", targetId.value));
        applyRoleChange(user, newRole);
        applyActiveChange(user, newActive);
        users.save(user);
        log.debug("User updated: id={}", targetId.value);
        return user;
    }

    private void applyRoleChange(AppUser user, PlatformRole newRole) {
        if (newRole == null) return;
        if (newRole == PlatformRole.PLATFORM_ADMIN) {
            user.promoteToPlatformAdmin();
        } else {
            user.demoteToUser();
        }
    }

    private void applyActiveChange(AppUser user, Boolean newActive) {
        if (newActive == null) return;
        if (newActive && !user.isActive()) {
            user.activate();
        } else if (!newActive && user.isActive()) {
            user.disable();
        }
    }
}
