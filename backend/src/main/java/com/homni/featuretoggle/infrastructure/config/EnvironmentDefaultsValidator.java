/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.config;

import com.homni.featuretoggle.domain.model.EnvironmentDefaults;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Logs the validated platform-wide default environment names at startup.
 * The actual validation is enforced earlier, when the {@link EnvironmentDefaults}
 * Spring bean is constructed: invalid config makes the bean factory throw,
 * which fails the application startup before this runner ever fires.
 */
@Component
@Profile("!test")
public class EnvironmentDefaultsValidator implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(EnvironmentDefaultsValidator.class);

    private final EnvironmentDefaults defaults;

    EnvironmentDefaultsValidator(EnvironmentDefaults defaults) {
        this.defaults = defaults;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (defaults.isEmpty()) {
            log.info("No default environments configured (app.environments.defaults is empty)");
        } else {
            log.info("Default environments configured: {}", defaults.all());
        }
    }
}
