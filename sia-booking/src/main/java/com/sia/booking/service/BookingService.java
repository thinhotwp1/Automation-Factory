package com.sia.booking.service;

import com.sia.booking.model.entity.Booking;
import com.sia.booking.model.request.BookingRequest;
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

    public boolean validatePnrCode(String pnrCode) {
        return pnrCode != null
                && pnrCode.matches("^[A-Z]{2}-\\d{5,10}$")
                && bookingRepository.findByPnrCode(pnrCode).isPresent();
    }

    public boolean cancelBookingByPnr(String pnrCode) {
        return bookingRepository.findByPnrCode(pnrCode)
                .map(booking -> {
                    booking.setStatus("CANCELLED");
                    bookingRepository.save(booking);
                    return true;
                })
                .orElse(false);
    }

    private String generatePNR() {
        return UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
