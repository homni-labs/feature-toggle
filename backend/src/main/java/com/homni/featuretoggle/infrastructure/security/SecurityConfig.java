/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.security;

import com.homni.featuretoggle.application.usecase.FindOrCreateUserUseCase;
import com.homni.featuretoggle.domain.model.AppUser;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.core.convert.converter.Converter;

import java.util.Arrays;
import java.util.List;

/**
 * Spring Security configuration for the feature toggle platform.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private static final Logger log = LoggerFactory.getLogger(SecurityConfig.class);

    private final ApiKeyAuthFilter apiKeyAuthFilter;
    private final SecurityErrorHandler securityErrorHandler;
    private final FindOrCreateUserUseCase findOrCreateUser;
    private final String issuerUri;
    private final String allowedOrigins;

    SecurityConfig(ApiKeyAuthFilter apiKeyAuthFilter,
                   SecurityErrorHandler securityErrorHandler,
                   FindOrCreateUserUseCase findOrCreateUser,
                   @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri:}") String issuerUri,
                   @Value("${app.cors.allowed-origins:http://localhost:3000}") String allowedOrigins) {
        this.apiKeyAuthFilter = apiKeyAuthFilter;
        this.securityErrorHandler = securityErrorHandler;
        this.findOrCreateUser = findOrCreateUser;
        this.issuerUri = issuerUri;
        this.allowedOrigins = allowedOrigins;
    }

    /**
     * Configures the security filter chain.
     *
     * @param http the HTTP security builder
     * @return the configured filter chain
     * @throws Exception if configuration fails
     */
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(this::configureAuthorization)
                .exceptionHandling(this::configureExceptionHandling)
                .addFilterBefore(apiKeyAuthFilter, UsernamePasswordAuthenticationFilter.class);
        configureOauth2(http);
        return http.build();
    }

    private void configureAuthorization(
            org.springframework.security.config.annotation.web.configurers.AuthorizeHttpRequestsConfigurer<HttpSecurity>.AuthorizationManagerRequestMatcherRegistry auth) {
        auth
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/actuator/**").permitAll()
                .requestMatchers("/swagger-ui/**", "/swagger-ui.html", "/docs", "/v3/api-docs/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/users/me").authenticated()
                .requestMatchers(HttpMethod.GET, "/users/search").authenticated()
                .requestMatchers("/users/**").hasRole("PLATFORM_ADMIN")
                .requestMatchers(HttpMethod.POST, "/projects").hasRole("PLATFORM_ADMIN")
                .anyRequest().authenticated();
    }

    private void configureExceptionHandling(
            org.springframework.security.config.annotation.web.configurers.ExceptionHandlingConfigurer<HttpSecurity> ex) {
        ex.authenticationEntryPoint(securityErrorHandler).accessDeniedHandler(securityErrorHandler);
    }

    private void configureOauth2(HttpSecurity http) throws Exception {
        if (issuerUri != null && !issuerUri.isBlank()) {
            http.oauth2ResourceServer(oauth2 -> oauth2
                    .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
            );
        }
    }

    private CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .forEach(config::addAllowedOriginPattern);
        config.setAllowedMethods(List.of("GET", "POST", "PATCH", "DELETE", "OPTIONS", "PUT", "PATCH"));
        config.setAllowedHeaders(List.of("Content-Type", "Authorization", "X-API-Key"));
        config.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    private Converter<Jwt, AbstractAuthenticationToken> jwtAuthenticationConverter() {
        return jwt -> {
            String subject = jwt.getSubject();
            if (subject == null) {
                log.warn("JWT missing 'sub' claim");
                throw new org.springframework.security.access.AccessDeniedException("Missing sub claim");
            }

            String email = jwt.getClaimAsString("email");
            if (email == null) {
                log.warn("JWT missing 'email' claim for sub={}", subject);
                throw new org.springframework.security.access.AccessDeniedException("Missing email claim");
            }

            String name = jwt.getClaimAsString("name");
            if (name == null) {
                name = jwt.getClaimAsString("preferred_username");
            }

            AppUser user = findOrCreateUser.execute(subject, email, name);

            if (!user.canAuthenticate()) {
                throw new org.springframework.security.access.AccessDeniedException("User is disabled");
            }

            List<GrantedAuthority> authorities =
                    List.of(new SimpleGrantedAuthority("ROLE_" + user.platformRole().name()));
            return new AppUserAuthentication(user, subject, authorities);
        };
    }
}
