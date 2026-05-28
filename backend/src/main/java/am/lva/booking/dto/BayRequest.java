package am.lva.booking.dto;

import jakarta.validation.constraints.NotBlank;

public record BayRequest(@NotBlank String name) {}
