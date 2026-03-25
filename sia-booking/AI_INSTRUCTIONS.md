# SIA Booking Service - Architecture & AI Developer Guidelines

## 1. Project Overview
This is the core Booking Service for the Singapore Airlines (SIA) backend system. It handles flight booking creations, validations, and downstream integrations.

## 2. Tech Stack
* **Language:** Java (Assume Java 21)
* **Framework:** Spring Boot 3.x
* **Build Tool:** Maven (`pom.xml`)
* **Key Libraries:** Lombok, Spring Web, Spring Data JPA (or standard Repositories).

## 3. Directory & Architecture Structure
The project strictly follows a Standard Layered Architecture. **DO NOT** create new architectural packages (like `domain` or `infrastructure`) unless explicitly instructed. Stick to the existing structure:

```text
src/main/java/com/sia/booking/
 ├── controller/       # REST endpoints (e.g., BookingController)
 ├── model/            # Data structures
 │    ├── entity/      # Database entities (e.g., Booking)
 │    └── request/     # DTOs for incoming requests (e.g., BookingRequest)
 ├── repository/       # Data access interfaces
 └── service/          # Business logic orchestration
```
 
## 4. API Design Conventions
When modifying or creating a new API, you MUST follow these rules:
Base Path: All endpoints must be versioned under /api/v1/....
Controllers: Use @RestController, @RequestMapping, and Lombok's @RequiredArgsConstructor for dependency injection. Do NOT use @Autowired on fields.
Request Handling: Use @Valid and @RequestBody with specific DTO classes from the model.request package. Never expose Entities directly in request payloads.
Response Handling: Always return ResponseEntity<T>. Wrap the response in standard HTTP status codes (e.g., ResponseEntity.ok(), ResponseEntity.created()).

## 5. Coding Standards for AI Agent
Lombok First: Utilize @Data, @Builder, @NoArgsConstructor, @AllArgsConstructor to minimize boilerplate.
Immutability: Mark injected service dependencies as private final.

## 6. Execution Workflow (Read Before Coding)
Read the specific instruction from the user.
Review this document for architectural boundaries.
Check existing files in the relevant packages before creating new ones to avoid duplication.
Output the exact file paths and the fully refactored Java code.
