/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.security.sso;

import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformRole;
import com.homni.togli.application.port.out.AppUserRepositoryPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("!test")
public class SsoConfigValidator implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(SsoConfigValidator.class);

    private final SsoProperties props;
    private final AppUserRepositoryPort userRepository;
    private final String issuerUri;

    SsoConfigValidator(SsoProperties props,
                       AppUserRepositoryPort userRepository,
                       @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri:}") String issuerUri) {
        this.props = props;
        this.userRepository = userRepository;
        this.issuerUri = issuerUri;
    }

    @Override
    public void run(ApplicationArguments args) {
        props.validate(issuerUri);
        log.info("SSO configuration validated: issuer-uri={}", issuerUri);
        provisionDefaultAdmin();
    }

    private void provisionDefaultAdmin() {
        String email = props.defaultAdminEmail();
        if (userRepository.findByEmail(email).isPresent()) {
            log.info("Default admin already exists: {}", email);
            return;
        }
        AppUser admin = new AppUser(email, "Admin", PlatformRole.PLATFORM_ADMIN);
        userRepository.save(admin);
        log.info("Default admin created (pending OIDC binding): {}", email);
    }
}