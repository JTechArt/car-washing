package am.lva.booking.dto;

import am.lva.booking.Booking;
import am.lva.booking.BookingStatus;
import java.time.OffsetDateTime;
import java.util.UUID;

public record BookingResponse(
        UUID id, UUID bayId, BookingStatus status,
        OffsetDateTime startsAt, OffsetDateTime endsAt) {
    public static BookingResponse from(Booking b) {
        return new BookingResponse(b.getId(), b.getBay().getId(),
                b.getStatus(), b.getStartsAt(), b.getEndsAt());
    }
}
