package com.sia.booking;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

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
        mockBooking.setPnrCode("SQ-12345");
        mockBooking.setStatus("CONFIRMED");
        bookingRepository.save(mockBooking);
    }

    /**
     * Test case for SIA booking cancellation.
     * 1. Validate PNR with pattern ^[A-Z]{2}-\d{5,10}$
     * 2. Execute cancellation logic via BookingService, use BookingRepository to execute with entity
     * 3. Verify status update in BookingRepository to 'CANCELLED'
     */
    @Test
    void shouldCancelBookingByPnrCodeSuccessfully() {
        String pnrCode = "SQ-12345";

        assertTrue(bookingService.validatePnrCode(pnrCode));
        assertTrue(bookingService.cancelBookingByPnr(pnrCode));

        Booking updatedBooking = bookingRepository.findByPnrCode(pnrCode)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        assertEquals("CANCELLED", updatedBooking.getStatus());
    }

    @Test
    void shouldRejectInvalidPnrFormat() {
        assertFalse(bookingService.validatePnrCode("INVALID-123"));
        assertFalse(bookingService.cancelBookingByPnr("INVALID-123"));
    }

    @Test
    void shouldReturnFalseWhenBookingNotFound() {
        String missingPnr = "SQ-99999";

        assertTrue(bookingService.validatePnrCode(missingPnr));
        assertFalse(bookingService.cancelBookingByPnr(missingPnr));
    }
}
