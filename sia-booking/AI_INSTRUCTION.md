# ARCHITECTURE_RULES
- stack: java21, spring_boot_3, maven
- libraries: lombok, spring_web, spring_data_jpa
- api_base: /api/v1/
- di: @RequiredArgsConstructor (NO @Autowired on fields)
- payload: Use DTOs. NEVER expose Entities in requests.
- response: ResponseEntity<T>
- exception: Throw specific (IllegalArgumentException, NotFoundException). No generic RuntimeException.
- dependencies: private final
- boundaries: Controller (HTTP) -> Service (Domain) -> Repository (Persistence).
