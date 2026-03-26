
# 🛫 Feature: Flight Booking Cancellation (SIA-001000)

> **Domain:** Booking Module | **Aggregate:** Booking | **Last Updated:** March 26, 2026 | **Status:** 🟢 Active

## 📖 Overview
This feature enables the system to process flight booking cancellations using a Passenger Name Record (PNR) Code. The workflow guarantees data integrity, strictly validates input formats to preserve system performance, and accurately mutates the ticket status within the database.

---

## ⚖️ Core Business Rules

* **BR-01: PNR Format Validation**
  A valid PNR code MUST adhere to the following strict regex structure (`^[A-Z]{2}-\d{5,10}$`):
    * Starts with **2 uppercase letters**.
    * Followed by **1 hyphen** (`-`).
    * Ends with **5 to 10 digits**.
    * *Examples of valid PNRs:* `VN-12345`, `SQ-0987654321`.
* **BR-02: Performance Constraint (Fail-Fast)**
  Format validation MUST occur at the outermost layer of the system. Querying the database with an invalidly formatted PNR is strictly prohibited to mitigate unnecessary system load and potential database abuse.

---

## 🚦 Use Case Scenarios

### ✅ Scenario 1: Successful Cancellation (Happy Path)
* **ID:** `SIA-001001`
* **Trigger:** The user requests to cancel a ticket with a valid PNR code that currently exists in the system.
* **System Actions:**
    1. Validate the PNR code format.
    2. Retrieve the booking record from the database.
    3. Update the ticket status to `CANCELLED`.
* **Outcome:** The system confirms a successful cancellation. The database reflects the `CANCELLED` status.

### ❌ Scenario 2: Invalid PNR Format
* **ID:** `SIA-001002`
* **Trigger:** The user provides a PNR string that violates the structural rules (e.g., `INVALID123`, missing a hyphen, or incorrect length).
* **System Actions:**
    1. Block the request immediately at the initial validation layer.
    2. Prevent any downstream database interactions.
* **Outcome:** The request is rejected. The system throws an `IllegalArgumentException` (or `400 Bad Request`) indicating: *"Invalid Passenger Name Record (PNR) format."*

### 🔍 Scenario 3: Missing Booking (Not Found)
* **ID:** `SIA-001003`
* **Trigger:** The user provides a structurally valid PNR, but no matching record exists in the database.
* **System Actions:**
    1. Validate the PNR format (Passes).
    2. Query the database for the record (Fails/Empty Result).
    3. Safely handle the missing entity.
* **Outcome:** The request is rejected. The system throws a `NotFoundException` (or `404 Not Found`) indicating: *"No booking information found matching the provided PNR code."*

---

## 🤖 AI Agent Implementation Notes
> **Spec-Driven Generation (SDG) Target**
> This document serves as the **Single Source of Truth** for the Automation Factory pipeline. The AI Agent must parse these rules to generate corresponding Unit/Integration Tests and Core Business Logic using the injected live context.

***
