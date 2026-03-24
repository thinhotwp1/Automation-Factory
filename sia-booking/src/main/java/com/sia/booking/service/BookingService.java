package com.sia.booking.service;

import com.sia.booking.model.entity.Booking;
import com.sia.booking.model.request.BookingRequest;
import com.sia.booking.model.request.UpdateBookingRequest;
import com.sia.booking.repository.BookingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;

    public Booking createBooking(BookingRequest request) {
        Booking booking = Booking.builder()
                .passengerName(request.getPassengerName())
                .flightNumber(request.getFlightNumber())
                .pnrCode(generatePNR())
                .status("CONFIRMED")
                .build();

        return bookingRepository.save(booking);
    }

    public Booking updateBooking(String id, UpdateBookingRequest request) {
        Long bookingId = Long.parseLong(id);
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with id: " + id));

        booking.setPassengerName(request.getPassengerName());
        booking.setFlightNumber(request.getFlightNumber());

        return bookingRepository.save(booking);
    }

    public boolean cancelBooking(String pnrCode) {
        Booking booking = bookingRepository.findByPnrCode(pnrCode)
                .orElseGet(() -> Booking.builder()
                        .pnrCode(pnrCode)
                        .status("CONFIRMED")
                        .build());

        booking.setStatus("CANCELLED");
        bookingRepository.save(booking);
        return true;
    }

    private String generatePNR() {
        return UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
