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
        mockBooking.setPnrCode("PC-12345");
        mockBooking.setStatus("CONFIRMED");
        bookingRepository.save(mockBooking);
    }

    /**
     * Test case for SIA booking cancellation with Passenger Name Record - PNR Code.
     * 1. Validate PNR with pattern ^[A-Z]{2}-\d{5,10}$
     * 2. Execute cancellation logic via BookingService, use BookingRepository to execute with entity
     * 3. Verify status update in BookingRepository to 'CANCELLED'
     */
    @Test
    void shouldCancelBookingByPnrCodeSuccessfully() {
    }
}
