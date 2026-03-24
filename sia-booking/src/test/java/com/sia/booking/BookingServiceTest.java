package com.sia.booking;

import com.sia.booking.service.BookingService;
import com.sia.booking.model.entity.Booking;
import com.sia.booking.model.request.BookingRequest;
import com.sia.booking.repository.BookingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookingServiceTest {

    @Mock
    private BookingRepository bookingRepository;

    @InjectMocks
    private BookingService bookingService;

    private BookingRequest request;

    @BeforeEach
    void setUp() {
        request = new BookingRequest();
        request.setPassengerName("John Doe");
        request.setFlightNumber("SQ321");
    }

    @Test
    void createBooking_ShouldReturnConfirmedBooking() {
        // Arrange
        Booking savedBooking = new Booking();
        savedBooking.setId(1L);
        savedBooking.setPassengerName("John Doe");
        savedBooking.setFlightNumber("SQ321");
        savedBooking.setStatus("CONFIRMED");
        savedBooking.setPnrCode("ABCDEF");

        when(bookingRepository.save(any(Booking.class))).thenReturn(savedBooking);

        // Act
        Booking result = bookingService.createBooking(request);

        // Assert
        assertNotNull(result);
        assertEquals("CONFIRMED", result.getStatus());
        assertEquals("John Doe", result.getPassengerName());
        assertNotNull(result.getPnrCode());
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }
}
