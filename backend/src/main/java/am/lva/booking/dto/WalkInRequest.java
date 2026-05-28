package am.lva.booking.dto;

import jakarta.validation.constraints.Min;

public record WalkInRequest(@Min(1) int estimatedDurationMinutes) {}
