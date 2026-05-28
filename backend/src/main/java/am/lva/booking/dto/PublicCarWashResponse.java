package am.lva.booking.dto;

import am.lva.booking.AvailabilityStatus;
import java.util.UUID;

public record PublicCarWashResponse(
        UUID id, String name, double lat, double lng,
        AvailabilityStatus availabilityStatus, int nextSlotMinutes) {}
