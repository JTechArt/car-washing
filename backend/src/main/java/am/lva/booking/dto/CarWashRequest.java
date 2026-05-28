package am.lva.booking.dto;

import jakarta.validation.constraints.NotBlank;

public record CarWashRequest(
        @NotBlank String name,
        @NotBlank String address,
        double lat,
        double lng) {}
