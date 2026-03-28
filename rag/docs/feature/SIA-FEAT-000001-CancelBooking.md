---
id: "SIA-FEAT-000001"
domain: "booking_module"
aggregate: "Booking"
category: "feature_specification"
tags: ["cancellation", "booking", "spec_driven_generation"]
target_test_file: "src/test/java/com/sia/booking/service/BookingServiceTest.java"
dictionary_dependencies: ["SIA-DICT-000001"]
bean_dependencies: ["com.sia.booking.service.BookingService", "com.sia.booking.repository.BookingRepository"]
author: "Architecture_Team"
last_updated: "2026-03-27"
---

# SIA-FEAT-000001: Feature Specification: Cancel Booking

## SIA-FEAT-000001-01: Successful Cancellation
- **Command/Intent**: Cancel a booking using a valid `PnrCode` object.
- **Pre-condition**: A mock booking exists in `BookingRepository` matching the provided `PnrCode` [[SIA-DICT-000001]]
- **Domain Logic**: Fetch the entity, mutate its internal status to `CANCELLED`, and persist it via `BookingRepository`.
- **Post-condition**: The method completes successfully. The database reflects the `CANCELLED` status.

## SIA-FEAT-000001-02: Invalid PNR Format Handling
- **Command/Intent**: Ensure the service gracefully handles validation failures from the Value Object.
- **Scenario**: The client provides an invalid PNR string (e.g., `INVALID123`).
- **Domain Logic**: The instantiation of `PnrCode` [[SIA-DICT-000001]] will fail. The Service layer MUST allow this `IllegalArgumentException` to bubble up or handle it via a global Exception Handler. It MUST NOT reach the repository layer.

## SIA-FEAT-000001-03: Missing Booking
- **Command/Intent**: Handle requests for non-existent aggregates.
- **Scenario**: The `PnrCode` [[SIA-DICT-000001]] is structurally valid, but `BookingRepository.findByPnr()` returns empty.
- **Expected Exception**: The system MUST throw a `BookingNotFoundException`.
