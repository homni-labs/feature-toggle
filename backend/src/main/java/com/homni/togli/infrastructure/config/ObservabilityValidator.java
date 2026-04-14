/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Map;

@Component
@Profile("!test")
public class ObservabilityValidator implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(ObservabilityValidator.class);

    private final ObservabilityProperties properties;

    ObservabilityValidator(ObservabilityProperties properties) {
        this.properties = properties;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!properties.enabled()) {
            log.info("Observability is disabled");
            return;
        }

        var missing = new ArrayList<String>();
        for (var entry : requiredProperties().entrySet()) {
            if (entry.getValue() == null || entry.getValue().isBlank()) {
                missing.add(entry.getKey());
            }
        }

        if (!missing.isEmpty()) {
            throw new IllegalStateException(
                    "Observability is enabled (OBSERVABILITY_ENABLED=true) but required environment variables are missing: "
                            + String.join(", ", missing)
            );
        }

        log.info("Observability enabled — Prometheus: {}", properties.prometheusUrl());
    }

    private Map<String, String> requiredProperties() {
        return Map.of(
                "PROMETHEUS_URL", properties.prometheusUrl()
        );
    }
}
