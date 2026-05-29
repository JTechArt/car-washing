package am.lva.booking.dto;

import am.lva.booking.Price;
import am.lva.booking.ServiceType;
import am.lva.booking.VehicleType;
import java.util.UUID;

public record PriceResponse(
        UUID id,
        VehicleType vehicleType,
        ServiceType serviceType,
        int durationMinutes,
        int amountAmd) {
    public static PriceResponse from(Price p) {
        return new PriceResponse(
                p.getId(), p.getVehicleType(), p.getServiceType(),
                p.getDurationMinutes(), p.getAmountAmd());
    }
}
