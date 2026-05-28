package am.lva.notifications;

import am.lva.booking.BayStatus;
import java.util.UUID;

public record BayStatusMessage(UUID bayId, BayStatus status) {}
