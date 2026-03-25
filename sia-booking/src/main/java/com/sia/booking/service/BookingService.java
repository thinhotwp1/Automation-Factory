package com.sia.booking.service;

import com.sia.booking.model.entity.Booking;
import com.sia.booking.model.request.BookingRequest;
import com.sia.booking.repository.BookingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class BookingService {

    private static final String CONFIRMED_STATUS = "CONFIRMED";

    private final BookingRepository bookingRepository;

    public Booking createBooking(BookingRequest request) {
        Booking booking = Booking.builder()
                .passengerName(request.getPassengerName())
                .flightNumber(request.getFlightNumber())
                .pnrCode(request.getPnrCode())
                .status(CONFIRMED_STATUS)
                .build();

        return bookingRepository.save(booking);
    }
}
