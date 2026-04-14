/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;

@SpringBootApplication
@ConfigurationPropertiesScan
public class TogliApplication {

    private static final Logger log = LoggerFactory.getLogger(TogliApplication.class);

    public static void main(String[] args) {
        SpringApplication.run(TogliApplication.class, args);
    }

    @EventListener(ApplicationReadyEvent.class)
    void logVersion() {
        String version = getClass().getPackage().getImplementationVersion();
        log.info("Togli Backend v{}", version != null ? version : "dev");
    }
}
