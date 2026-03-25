package com.sia.booking.model.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BookingRequest {
    @NotBlank(message = "Passenger name is required")
    private String passengerName;

    @NotBlank(message = "Flight number is required")
    private String flightNumber;

    @NotBlank(message = "Passenger Name Record")
    private String pnrCode;
}
