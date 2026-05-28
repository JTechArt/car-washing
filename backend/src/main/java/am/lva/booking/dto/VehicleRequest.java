package am.lva.booking.dto;

import am.lva.booking.VehicleType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record VehicleRequest(
        @NotBlank String plate,
        @NotNull VehicleType type,
        String nickname) {}
