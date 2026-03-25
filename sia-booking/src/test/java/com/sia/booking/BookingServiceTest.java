package com.sia.booking;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import com.sia.booking.model.entity.Booking;
import com.sia.booking.repository.BookingRepository;
import com.sia.booking.service.BookingService;

@SpringBootTest
class BookingServiceTest {

    @Autowired
    private BookingService bookingService;

    @Autowired
    private BookingRepository bookingRepository;

    @BeforeEach
    void setUp() {
        bookingRepository.deleteAll();

        Booking mockBooking = new Booking();
        mockBooking.setPassengerName("John Doe");
        mockBooking.setFlightNumber("SQ123");
        mockBooking.setPnrCode("SQ-12345");
        mockBooking.setStatus("CONFIRMED");
        bookingRepository.save(mockBooking);
    }

    /**
     * Test case 1: Happy Path - Successful Cancellation.
     * 1. Validate PNR with pattern ^[A-Z]{2}-\d{5,10}$
     * 2. Execute cancellation logic via BookingService, use BookingRepository to execute with entity
     * 3. Verify status update in BookingRepository to 'CANCELLED'
     */
    @Test
    void shouldCancelBookingByPnrCodeSuccessfully() {
    }

    /**
     * Test case 2: Validation Failure - Invalid PNR Format.
     * 1. Provide a PNR that violates the pattern ^[A-Z]{2}-\d{5,10}$ (e.g., missing hyphen, wrong length).
     * 2. Expect an IllegalArgumentException to be thrown before reaching the database.
     * 3. Ensure this logic prevents unnecessary database queries.
     */
    @Test
    void shouldThrowExceptionWhenPnrFormatIsInvalid() {
    }

    /**
     * Test case 3: Data Not Found - Valid PNR but non-existent record.
     * 1. Provide a PNR that matches the regex pattern but does not exist in the database.
     * 2. Execute cancellation logic.
     * 3. Expect a RuntimeException (or NotFoundException) indicating the booking is missing.
     */
    @Test
    void shouldThrowExceptionWhenBookingNotFound() {
    }
}
