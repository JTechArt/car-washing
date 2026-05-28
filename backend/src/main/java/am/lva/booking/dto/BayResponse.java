package am.lva.booking.dto;

import am.lva.booking.Bay;
import am.lva.booking.BayStatus;
import java.util.UUID;

public record BayResponse(UUID id, String name, BayStatus status) {
    public static BayResponse from(Bay b) {
        return new BayResponse(b.getId(), b.getName(), b.getStatus());
    }
}
