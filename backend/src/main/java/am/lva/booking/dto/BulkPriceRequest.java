package am.lva.booking.dto;

import am.lva.booking.ServiceType;
import am.lva.booking.VehicleType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record BulkPriceRequest(List<PriceEntry> prices) {
    public record PriceEntry(
            @NotNull VehicleType vehicleType,
            @NotNull ServiceType serviceType,
            @Min(1) int durationMinutes,
            @Min(0) int amountAmd) {}
}
