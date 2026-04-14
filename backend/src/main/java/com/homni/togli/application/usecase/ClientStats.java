/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import java.time.Instant;

/**
 * Aggregated usage statistics for an API key.
 *
 * @param lastUsedAt  most recent client activity, or {@code null} if never used
 * @param clientCount number of distinct clients
 */
public record ClientStats(Instant lastUsedAt, long clientCount) {
}
