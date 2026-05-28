package am.lva.booking.dto;

import am.lva.booking.Vehicle;
import am.lva.booking.VehicleType;
import java.util.UUID;

public record VehicleResponse(UUID id, String plate, VehicleType type, String nickname) {
    public static VehicleResponse from(Vehicle v) {
        return new VehicleResponse(v.getId(), v.getPlate(), v.getType(), v.getNickname());
    }
}
