package am.lva.booking.dto;

import am.lva.booking.CarWash;
import java.util.UUID;

public record CarWashResponse(UUID id, String name, String address, double lat, double lng) {
    public static CarWashResponse from(CarWash w) {
        return new CarWashResponse(w.getId(), w.getName(), w.getAddress(), w.getLat(), w.getLng());
    }
}
