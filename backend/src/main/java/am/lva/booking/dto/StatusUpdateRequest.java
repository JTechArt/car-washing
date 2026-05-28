package am.lva.booking.dto;

import am.lva.booking.BookingStatus;
import jakarta.validation.constraints.NotNull;

public record StatusUpdateRequest(@NotNull BookingStatus status) {}
