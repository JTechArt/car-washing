package am.lva.booking.dto;

import java.time.OffsetDateTime;

public record SlotResponse(OffsetDateTime startsAt, int durationMinutes, int amountAmd) {}
