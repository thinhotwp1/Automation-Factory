package com.sia.booking.repository;

import com.sia.booking.model.entity.Booking;
import org.springframework.data.jpa.repository.JpaRepository;


public interface BookingRepository extends JpaRepository<Booking, Long> {
}
