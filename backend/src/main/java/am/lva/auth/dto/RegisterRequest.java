package am.lva.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record RegisterRequest(@NotBlank String phone, @NotBlank String password) {}
