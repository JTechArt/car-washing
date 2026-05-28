package am.lva.booking.dto;

import jakarta.validation.constraints.NotNull;
import java.time.OffsetDateTime;
import java.util.UUID;

public record BookingRequest(
        @NotNull UUID carWashId,
        @NotNull UUID vehicleId,
        @NotNull String serviceType,
        @NotNull OffsetDateTime slotStartsAt) {}
