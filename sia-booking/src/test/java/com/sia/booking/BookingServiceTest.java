package com.sia.booking;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.sia.booking.model.entity.Booking;
import com.sia.booking.model.request.BookingRequest;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import com.sia.booking.service.BookingService;

// File: src/test/java/com/sia/booking/service/BookingServiceTest.java
@SpringBootTest
class BookingServiceTest {
    @Autowired
    private BookingService bookingService;

    @Test
    void shouldCreateBookingSuccessfully() {
        BookingRequest request = new BookingRequest();
        request.setPassengerName("Test Passenger");
        request.setFlightNumber("SQ321");

        Booking result = bookingService.createBooking(request);

        assertNotNull(result, "Booking should be created");
        assertEquals("CONFIRMED", result.getStatus(), "Booking should be confirmed");
    }
}
