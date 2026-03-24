package com.sia.booking.model.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.Date;

@Entity
@Table(name = "bookings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Booking {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String passengerName;
    private String flightNumber; // Ex: SQ321
    private String pnrCode;      // Passenger Name Record
    private Date bookingTime;
    private String status;       // CONFIRMED, CANCELLED

    @PrePersist
    private void prePersist(){
        this.bookingTime = new Date(System.currentTimeMillis());
    }

}
