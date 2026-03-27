# ARCHITECTURE
- Stack: Java 21, Spring Boot 3, Maven, Layered (Controller->Service->Repo).
- DI: `@RequiredArgsConstructor`, `private final`. NO field `@Autowired`.
- I/O: `/api/v1/`, `ResponseEntity<T>`, DTOs only. NO Entities.
- Errors: Specific exceptions only. NO generic `RuntimeException`.

# AI_RULES (STRICT)
- TRACEABILITY: Annotate ALL test & prod methods with `@BusinessRule`.
- MULTI-MAPPING: Share methods via arrays: `@BusinessRule({"ID-1", "ID-2"})`.
- OVERWRITE: FORCE update logic to match new specs. NEVER say "already aligned" or skip.
- PRESERVE: KEEP existing IDs in `@BusinessRule` arrays when adding/updating targets.
