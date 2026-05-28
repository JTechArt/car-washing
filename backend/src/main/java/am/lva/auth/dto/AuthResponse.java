package am.lva.auth.dto;

import am.lva.auth.UserRole;

public record AuthResponse(String token, UserRole role) {}
