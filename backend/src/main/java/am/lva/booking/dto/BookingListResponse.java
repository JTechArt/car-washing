package am.lva.booking.dto;

import am.lva.booking.Booking;
import am.lva.booking.BookingStatus;

import java.time.OffsetDateTime;
import java.util.UUID;

public record BookingListResponse(
        UUID id,
        UUID bayId,
        String carWashName,
        String bayName,
        BookingStatus status,
        OffsetDateTime startsAt,
        OffsetDateTime endsAt,
        String serviceType,
        UUID vehicleId) {

    public static BookingListResponse from(Booking b) {
        return new BookingListResponse(
                b.getId(),
                b.getBay().getId(),
                b.getBay().getCarWash().getName(),
                b.getBay().getName(),
                b.getStatus(),
                b.getStartsAt(),
                b.getEndsAt(),
                b.getServiceType().name(),
                b.getVehicle().getId());
    }
}
