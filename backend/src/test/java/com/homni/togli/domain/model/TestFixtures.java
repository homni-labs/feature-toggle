/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Shared randomized data generators for domain model tests.
 *
 * <p>Every call produces fresh values so that tests verify invariants
 * rather than passing by coincidence with hardcoded data.
 */
final class TestFixtures {

    private TestFixtures() {
        throw new AssertionError("No instances");
    }

    static String randomName() {
        return "toggle-" + UUID.randomUUID().toString().substring(0, 8);
    }

    static String randomDescription() {
        return "desc-" + UUID.randomUUID().toString().substring(0, 12);
    }

    static String randomSuffix() {
        return UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }

    static ProjectSlug randomSlug() {
        return new ProjectSlug("PRJ-" + randomSuffix());
    }

    static String randomEmail() {
        return "user-" + UUID.randomUUID().toString().substring(0, 8) + "@test.com";
    }

    static String randomOidcSubject() {
        return "oidc-" + UUID.randomUUID();
    }

    static Instant randomPastInstant() {
        long min = Instant.parse("2024-01-01T00:00:00Z").getEpochSecond();
        long max = Instant.now().getEpochSecond();
        return Instant.ofEpochSecond(ThreadLocalRandom.current().nextLong(min, max));
    }

    static Set<String> randomEnvSet(int size) {
        var envs = new LinkedHashSet<String>(size);
        while (envs.size() < size) {
            envs.add("ENV_" + randomSuffix());
        }
        return Set.copyOf(envs);
    }

    static Set<String> randomSubset(Set<String> source) {
        var list = new ArrayList<>(source);
        Collections.shuffle(list);
        int take = ThreadLocalRandom.current().nextInt(1, list.size() + 1);
        return Set.copyOf(list.subList(0, take));
    }
}