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

    private static final String PNR_REGEX = "^[A-Z]{2}-\\d{5,10}$";
    private static final String CONFIRMED_STATUS = "CONFIRMED";
    private static final String CANCELLED_STATUS = "CANCELLED";

    private final BookingRepository bookingRepository;

    public Booking createBooking(BookingRequest request) {
        Booking booking = Booking.builder()
                .passengerName(request.getPassengerName())
                .flightNumber(request.getFlightNumber())
                .pnrCode(generatePNR())
                .status(CONFIRMED_STATUS)
                .build();

        return bookingRepository.save(booking);
    }

    public boolean validatePnrCode(String pnrCode) {
        return pnrCode != null && pnrCode.matches(PNR_REGEX);
    }

    public boolean cancelBookingByPnr(String pnrCode) {
        if (!validatePnrCode(pnrCode)) {
            return false;
        }

        return bookingRepository.findByPnrCode(pnrCode)
                .map(booking -> {
                    booking.setStatus(CANCELLED_STATUS);
                    bookingRepository.save(booking);
                    return true;
                })
                .orElse(false);
    }

    public boolean cancelBooking(String pnrCode) {
        return cancelBookingByPnr(pnrCode);
    }

    private String generatePNR() {
        return UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
