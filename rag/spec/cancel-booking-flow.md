---
id: "SIA-001000"
domain: "booking_module"
aggregate: "Booking"
category: "feature_specification"
tags: ["cancellation", "booking", "spec_driven_generation"]
target_test_file: "src/test/java/com/sia/booking/BookingServiceTest.java"
dependencies: ["com.sia.booking.service.BookingService", "com.sia.booking.repository.BookingRepository"]
author: "Architecture_Team"
last_updated: "2026-03-25"
---

# Feature Specification: Cancel Booking (SIA-001000)
This specification defines the behavior for cancelling a flight booking. The AI Agent MUST generate both the Unit/Integration Tests and the Core Business Logic using the dependencies defined in the metadata.

## SIA-001001: Successful Cancellation
- **Command/Intent**: Cancel a booking using a valid PNR Code.
- **Pre-condition**: Persist a mock booking via `BookingRepository`. The PNR Code matches the standard SIA pattern (`^[A-Z]{2}-\d{5,10}$`) AND the record exists in the Database.
- **Domain Logic**: Execute the cancellation logic via `BookingService`.
- **State Mutation (Repository)**: Use `BookingRepository` to fetch the entity just saved, change its internal status to `CANCELLED`, and save it.
- **Post-condition**: The method returns `true` or successfully completes without exceptions. The database reflects the `CANCELLED` status.

## SIA-001002: Invalid PNR Format
- **Command/Intent**: Prevent invalid PNR inputs from reaching the database layer.
- **Scenario**: The provided PNR string violates the regex pattern `^[A-Z]{2}-\d{5,10}$` (e.g., missing hyphen like `INVALID123`).
- **Domain Logic**: This is a strict input invariant check. It MUST occur before any repository methods are invoked.
- **Expected Exception**: The system MUST immediately throw an `IllegalArgumentException`.

## SIA-001003: Missing Booking
- **Command/Intent**: Handle requests for non-existent aggregates.
- **Scenario**: The PNR format is perfectly valid, but no matching `Booking` aggregate is found in the `BookingRepository`.
- **Domain Logic**: The service must explicitly handle the empty result (e.g., from an `Optional` return type).
- **Expected Exception**: The system MUST throw a `RuntimeException` (or domain-specific `NotFoundException`) stating that the booking could not be found.
