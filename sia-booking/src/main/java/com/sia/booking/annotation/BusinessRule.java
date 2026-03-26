package com.sia.booking.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marker annotation for Spec-Driven Generation.
 * Links this code block directly to a Vector DB Specification ID.
 */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.SOURCE) // Scope Source Code for AI/Dev, not in Runtime
public @interface BusinessRule {
    String value(); // Spec ID, ex: "SIA-001001"
}
