/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.port.out;

import com.homni.featuretoggle.domain.model.FeatureToggle;
import com.homni.featuretoggle.domain.model.FeatureToggleId;
import com.homni.featuretoggle.domain.model.ProjectId;

import java.util.List;
import java.util.Optional;

/**
 * Output port for persisting feature toggles scoped to a project.
 */
public interface FeatureToggleRepositoryPort {

    /**
     * Saves a feature toggle (insert or update).
     *
     * @param toggle the toggle to save
     */
    void save(FeatureToggle toggle);

    /**
     * Finds a feature toggle by identity.
     *
     * @param id toggle identity
     * @return the toggle if found, or empty
     */
    Optional<FeatureToggle> findById(FeatureToggleId id);

    /**
     * Lists toggles for a project with filtering and pagination.
     *
     * @param projectId   owning project identity
     * @param enabled     enabled filter, or {@code null}
     * @param environment environment filter, or {@code null}
     * @param offset      rows to skip
     * @param limit       max rows to return
     * @return the matching toggles
     */
    List<FeatureToggle> findAllByProject(ProjectId projectId, Boolean enabled, String environment,
                                         int offset, int limit);

    /**
     * Counts toggles matching the given filters.
     *
     * @param projectId   owning project identity
     * @param enabled     enabled filter, or {@code null}
     * @param environment environment filter, or {@code null}
     * @return the matching count
     */
    long countByProject(ProjectId projectId, Boolean enabled, String environment);

    /**
     * Deletes a feature toggle by identity.
     *
     * @param id toggle identity
     */
    void deleteById(FeatureToggleId id);

    /**
     * Disables every enabled toggle in a project in a single bulk update.
     * Used when archiving a project so no toggle can remain switched on.
     *
     * @param projectId owning project identity
     * @return number of toggles that were disabled
     */
    int disableAllByProject(ProjectId projectId);
}
