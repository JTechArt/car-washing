package am.lva.booking.dto;

import am.lva.booking.Bay;
import am.lva.booking.BayStatus;

import java.util.UUID;

public record BayResponse(
        UUID id,
        String name,
        BayStatus status,
        UUID activeBookingId,
        String activeBookingStatus
) {
    public static BayResponse from(Bay b) {
        return new BayResponse(b.getId(), b.getName(), b.getStatus(), null, null);
    }

    public static BayResponse from(Bay b, UUID bookingId, String bookingStatus) {
        return new BayResponse(b.getId(), b.getName(), b.getStatus(), bookingId, bookingStatus);
    }
}
