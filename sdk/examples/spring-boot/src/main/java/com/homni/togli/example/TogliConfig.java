package com.homni.togli.example;

import com.homni.togli.sdk.TogliClient;
import com.homni.togli.sdk.TogliClients;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class TogliConfig {

    private static final Logger log = LoggerFactory.getLogger(TogliConfig.class);

    @Bean
    TogliClient togliClient(
            @Value("${togli.base-url}") String baseUrl,
            @Value("${togli.api-key}") String apiKey,
            @Value("${togli.project-slug}") String projectSlug,
            @Value("${togli.default-environment}") String defaultEnv,
            @Value("${togli.service-name}") String serviceName,
            @Value("${togli.namespace:#{null}}") String namespace
    ) {
        var builder = TogliClients.builder()
                .baseUrl(baseUrl)
                .apiKey(apiKey)
                .projectSlug(projectSlug)
                .serviceName(serviceName)
                .defaultEnvironment(defaultEnv)
                .onError(e -> log.warn("Toggle error: {}", e.getMessage()))
                .onReady(c -> log.info("Togli SDK ready — {} toggles loaded", c.allToggles().size()));

        if (namespace != null) {
            builder.namespace(namespace);
        }

        return builder.build();
    }
}
