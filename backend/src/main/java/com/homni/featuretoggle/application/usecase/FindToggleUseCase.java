/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.CallerProjectAccessPort;
import com.homni.featuretoggle.application.port.out.FeatureToggleRepositoryPort;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.model.FeatureToggle;
import com.homni.featuretoggle.domain.model.FeatureToggleId;
import com.homni.featuretoggle.domain.model.Permission;

/**
 * Finds a feature toggle by identity.
 */
public final class FindToggleUseCase {

    private final FeatureToggleRepositoryPort toggles;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param toggles      toggle persistence port
     * @param callerAccess caller's project access resolver
     */
    public FindToggleUseCase(FeatureToggleRepositoryPort toggles,
                              CallerProjectAccessPort callerAccess) {
        this.toggles = toggles;
        this.callerAccess = callerAccess;
    }

    /**
     * Finds a toggle and verifies read access.
     *
     * @param id toggle identity
     * @return the found feature toggle
     * @throws EntityNotFoundException if the toggle does not exist
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks READ_TOGGLES
     */
    public FeatureToggle execute(FeatureToggleId id) {
        FeatureToggle toggle = toggles.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Toggle", id.value));
        callerAccess.resolve(toggle.projectId).ensure(Permission.READ_TOGGLES);
        return toggle;
    }
}
