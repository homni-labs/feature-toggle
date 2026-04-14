/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.exception;

import com.homni.togli.domain.exception.DomainAccessDeniedException;
import com.homni.togli.domain.exception.DomainConflictException;
import com.homni.togli.domain.exception.DomainNotFoundException;
import com.homni.togli.domain.exception.DomainValidationException;
import com.homni.generated.model.ErrorResponse;
import com.homni.generated.model.ErrorResponsePayload;
import com.homni.generated.model.ResponseMeta;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import jakarta.validation.ConstraintViolationException;
import java.time.OffsetDateTime;
import java.util.stream.Collectors;

/**
 * Maps domain and framework exceptions to HTTP error responses.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // -- Domain exceptions ---------------------------------------------------

    /**
     * Handles domain access-denied exceptions.
     *
     * @param e the exception
     * @return 403 error response
     */
    @ExceptionHandler(DomainAccessDeniedException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public ErrorResponse handleAccessDenied(DomainAccessDeniedException e) {
        log.warn("Access denied: {}", e.getMessage());
        return error("FORBIDDEN", e.getMessage());
    }

    /**
     * Handles domain not-found exceptions.
     *
     * @param e the exception
     * @return 404 error response
     */
    @ExceptionHandler(DomainNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handleNotFound(DomainNotFoundException e) {
        log.warn("Resource not found: {}", e.getMessage());
        return error("NOT_FOUND", e.getMessage());
    }

    /**
     * Handles domain conflict exceptions.
     *
     * @param e the exception
     * @return 409 error response
     */
    @ExceptionHandler(DomainConflictException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ErrorResponse handleConflict(DomainConflictException e) {
        log.warn("Conflict: {}", e.getMessage());
        return error("CONFLICT", e.getMessage());
    }

    /**
     * Handles domain validation exceptions.
     *
     * @param e the exception
     * @return 422 error response
     */
    @ExceptionHandler(DomainValidationException.class)
    @ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
    public ErrorResponse handleDomainValidation(DomainValidationException e) {
        log.warn("Domain validation failed: {}", e.getMessage());
        return error("VALIDATION_ERROR", e.getMessage());
    }

    // -- Validation exceptions -----------------------------------------------

    /**
     * Handles Spring bean validation failures.
     *
     * @param e the exception
     * @return 400 error response
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleValidation(MethodArgumentNotValidException e) {
        String details = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getField() + ": " + f.getDefaultMessage())
                .collect(Collectors.joining("; "));
        log.warn("Validation failed: {}", details);
        return error("VALIDATION_ERROR", "Validation failed", details);
    }

    /**
     * Handles Jakarta constraint violations.
     *
     * @param e the exception
     * @return 400 error response
     */
    @ExceptionHandler(ConstraintViolationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleConstraintViolation(ConstraintViolationException e) {
        String details = e.getConstraintViolations().stream()
                .map(v -> v.getPropertyPath() + ": " + v.getMessage())
                .collect(Collectors.joining("; "));
        log.warn("Constraint violation: {}", details);
        return error("VALIDATION_ERROR", "Validation failed", details);
    }

    /**
     * Handles missing request parameters.
     *
     * @param e the exception
     * @return 400 error response
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleMissingParam(MissingServletRequestParameterException e) {
        log.warn("Missing parameter: {}", e.getMessage());
        return error("MISSING_PARAM", e.getMessage());
    }

    /**
     * Handles request parameter type mismatches.
     *
     * @param e the exception
     * @return 400 error response
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleTypeMismatch(MethodArgumentTypeMismatchException e) {
        Class<?> requiredType = e.getRequiredType();
        String typeName = requiredType != null ? requiredType.getSimpleName() : "unknown";
        String message = "Parameter '" + e.getName() + "' must be of type " + typeName;
        log.warn("Type mismatch: {}", message);
        return error("INVALID_PARAM", message);
    }

    /**
     * Handles illegal argument exceptions.
     *
     * @param e the exception
     * @return 400 error response
     */
    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleBadRequest(IllegalArgumentException e) {
        log.warn("Bad request: {}", e.getMessage());
        return error("BAD_REQUEST", e.getMessage());
    }

    // -- Infrastructure exceptions -------------------------------------------

    /**
     * Catches all unhandled exceptions.
     *
     * @param e the exception
     * @return 500 error response
     */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ErrorResponse handleUnexpected(Exception e) {
        log.error("Unhandled exception", e);
        return error("INTERNAL_ERROR", "An unexpected error occurred");
    }

    // -- Helpers -------------------------------------------------------------

    private ErrorResponse error(String code, String message) {
        return error(code, message, null);
    }

    private ErrorResponse error(String code, String message, String details) {
        ErrorResponsePayload payload = new ErrorResponsePayload(code, message);
        payload.setDetails(details);
        return new ErrorResponse(payload, new ResponseMeta().timestamp(OffsetDateTime.now()));
    }
}
