---
id: "SIA-FEAT-000002"
domain: "booking_module"
aggregate: "Booking"
category: "feature_specification"
tags: ["creation", "booking", "spec_driven_generation"]
target_test_file: "src/test/java/com/sia/booking/service/BookingServiceTest.java"
dictionary_dependencies: ["SIA-DICT-000001"]
bean_dependencies: ["com.sia.booking.service.BookingService", "com.sia.booking.repository.BookingRepository"]
author: "Architecture_Team"
last_updated: "2026-03-27"
---

# SIA-FEAT-000002: Feature Specification: Create Booking

## SIA-FEAT-000002-01: Successful Booking Creation
- **Command/Intent**: Create a new flight booking for a passenger and assign a unique PNR.
- **Pre-condition**: The provided flight schedule exists and has available seats. The passenger details are valid.
- **Domain Logic**: Instantiate a new `Booking` entity. The service MUST generate a random, unique `PnrCode` that strictly complies with the regex defined in [[SIA-DICT-000001]]. Set the initial status to `CONFIRMED`.
- **State Mutation (Repository)**: Persist the new entity via `BookingRepository.save()`.
- **Post-condition**: The method returns the generated `PnrCode` object. The database reflects the newly inserted record.

## SIA-FEAT-000002-02: PNR Collision Handling
- **Command/Intent**: Ensure absolute uniqueness of the Booking Reference across the system.
- **Scenario**: The randomly generated `PnrCode` string already exists in the `BookingRepository`.
- **Domain Logic**: Before saving, the service MUST check if the generated PNR exists using `BookingRepository.existsByPnrCode()`. If it exists, the system MUST retry generating a new PNR up to 3 times.
- **Expected Exception**: If it fails to generate a unique PNR after 3 attempts, throw a `RuntimeException` (or domain-specific `PnrGenerationException`).

## SIA-FEAT-000002-03: Invalid Input Data
- **Command/Intent**: Prevent booking creation with incomplete or null domain data.
- **Scenario**: The incoming creation request contains a null `flightId` or empty passenger details.
- **Domain Logic**: Validate input boundaries before initiating the PNR generation process.
- **Expected Exception**: The system MUST immediately throw an `IllegalArgumentException` indicating the missing mandatory fields.
