/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.http;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import com.homni.togli.sdk.application.port.out.TogliApiPort;
import com.homni.togli.sdk.domain.exception.TogliAccessDeniedException;
import com.homni.togli.sdk.domain.exception.TogliAuthenticationException;
import com.homni.togli.sdk.domain.exception.TogliNetworkException;
import com.homni.togli.sdk.domain.exception.TogliNotFoundException;
import com.homni.togli.sdk.domain.exception.TogliParsingException;
import com.homni.togli.sdk.domain.exception.TogliServerException;
import com.homni.togli.sdk.domain.model.EnvironmentInfo;
import com.homni.togli.sdk.domain.model.EnvironmentPage;
import com.homni.togli.sdk.domain.model.Pagination;
import com.homni.togli.sdk.domain.model.ProjectInfo;
import com.homni.togli.sdk.domain.model.Toggle;
import com.homni.togli.sdk.domain.model.TogglePage;
import com.homni.togli.sdk.domain.model.ToggleState;
import com.homni.togli.sdk.infrastructure.config.TogliConfiguration;

/**
 * HTTP-based implementation of {@link TogliApiPort}.
 *
 * <p>Uses {@link java.net.http.HttpClient} to communicate with the Togli API
 * and the internal {@link JsonParser} to parse responses. This class is
 * thread-safe because {@link HttpClient} is thread-safe and all state is
 * effectively immutable after construction.
 */
public final class HttpTogliApiAdapter implements TogliApiPort {

    private static final String VERSION = "0.1.0";

    private final HttpClient httpClient;
    private final ApiUrls urls;
    private final String apiKey;
    private final TogliConfiguration config;

    /**
     * Creates a new adapter configured from the given configuration.
     *
     * @param config the SDK configuration, must not be {@code null}
     */
    public HttpTogliApiAdapter(TogliConfiguration config) {
        if (config == null) {
            throw new IllegalArgumentException("config must not be null");
        }
        this.config = config;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(config.connectTimeout)
                .build();
        this.urls = new ApiUrls(config.baseUrl);
        this.apiKey = config.apiKey;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public ProjectInfo fetchProjectBySlug(String slug) {
        String url = urls.projectBySlug(slug);
        JsonObject json = executeGet(url);
        return parseProjectInfo(json.object("payload"));
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public TogglePage fetchToggles(String projectId, int page, int size) {
        String url = urls.toggles(projectId, page, size);
        JsonObject json = executeGet(url);
        JsonArray payload = json.array("payload");
        List<Toggle> toggles = new ArrayList<>(payload.size());
        for (JsonObject item : payload) {
            toggles.add(parseToggle(item));
        }
        Pagination pagination = parsePagination(json.object("pagination"));
        return new TogglePage(toggles, pagination);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Toggle fetchToggle(String projectId, String toggleId) {
        String url = urls.toggle(projectId, toggleId);
        JsonObject json = executeGet(url);
        return parseToggle(json.object("payload"));
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public EnvironmentPage fetchEnvironments(String projectId, int page, int size) {
        String url = urls.environments(projectId, page, size);
        JsonObject json = executeGet(url);
        JsonArray payload = json.array("payload");
        List<EnvironmentInfo> environments = new ArrayList<>(payload.size());
        for (JsonObject item : payload) {
            environments.add(parseEnvironmentInfo(item));
        }
        Pagination pagination = parsePagination(json.object("pagination"));
        return new EnvironmentPage(environments, pagination);
    }

    // ---- HTTP ----

    private JsonObject executeGet(String url) {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .GET()
                .header("X-API-Key", apiKey)
                .header("Accept", "application/json")
                .header("X-Togli-Service", config.serviceName)
                .header("X-Togli-SDK", "togli-java/" + VERSION)
                .timeout(config.requestTimeout);

        if (config.namespace != null) {
            builder.header("X-Togli-Namespace", config.namespace);
        }

        HttpRequest request = builder.build();

        HttpResponse<String> response;
        try {
            response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (IOException e) {
            throw new TogliNetworkException(
                    "Failed to communicate with Togli API: " + e.getMessage(), e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new TogliNetworkException("Request interrupted", e);
        }

        int status = response.statusCode();
        String body = response.body();

        if (status == 200) {
            return JsonParser.parse(body);
        }
        if (status == 401) {
            throw new TogliAuthenticationException();
        }
        if (status == 403) {
            String message = extractErrorMessage(body, "Access denied");
            throw new TogliAccessDeniedException(message);
        }
        if (status == 404) {
            String message = extractErrorMessage(body, "Resource not found");
            throw new TogliNotFoundException("Resource", message);
        }

        String errorCode = "SERVER_ERROR";
        String errorMessage = "Unexpected status " + status;
        try {
            JsonObject errorJson = JsonParser.parse(body);
            JsonObject payload = errorJson.object("payload");
            errorCode = payload.string("code");
            errorMessage = payload.string("message");
        } catch (TogliParsingException ignored) {
            // Use defaults if error body cannot be parsed
        }
        throw new TogliServerException(status, errorCode, errorMessage);
    }

    private String extractErrorMessage(String body, String fallback) {
        try {
            JsonObject errorJson = JsonParser.parse(body);
            JsonObject payload = errorJson.object("payload");
            return payload.string("message");
        } catch (TogliParsingException ignored) {
            return fallback;
        }
    }

    // ---- Parsing ----

    private ProjectInfo parseProjectInfo(JsonObject obj) {
        return new ProjectInfo(
                obj.string("id"),
                obj.string("slug"),
                obj.string("name"),
                obj.optString("description"),
                obj.bool("archived"),
                parseInstant(obj.string("createdAt")),
                obj.optString("updatedAt").map(this::parseInstant)
        );
    }

    private Toggle parseToggle(JsonObject obj) {
        JsonArray envArray = obj.array("environments");
        List<ToggleState> states = new ArrayList<>(envArray.size());
        for (JsonObject env : envArray) {
            states.add(new ToggleState(env.string("name"), env.bool("enabled")));
        }
        return new Toggle(
                obj.string("id"),
                obj.string("projectId"),
                obj.string("name"),
                obj.optString("description"),
                states,
                parseInstant(obj.string("createdAt")),
                obj.optString("updatedAt").map(this::parseInstant)
        );
    }

    private EnvironmentInfo parseEnvironmentInfo(JsonObject obj) {
        return new EnvironmentInfo(
                obj.string("id"),
                obj.string("projectId"),
                obj.string("name"),
                parseInstant(obj.string("createdAt"))
        );
    }

    private Pagination parsePagination(JsonObject obj) {
        return new Pagination(
                obj.integer("page"),
                obj.integer("size"),
                obj.longValue("totalElements"),
                obj.integer("totalPages")
        );
    }

    private Instant parseInstant(String iso) {
        try {
            return Instant.parse(iso);
        } catch (java.time.format.DateTimeParseException e) {
            throw new TogliParsingException("Invalid ISO-8601 timestamp: " + iso);
        }
    }
}
