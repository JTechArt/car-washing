package am.lva.booking;

import am.lva.booking.dto.SlotResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SlotService {

    private final BayRepository bayRepository;
    private final PriceRepository priceRepository;
    private final BookingRepository bookingRepository;

    public List<SlotResponse> getAvailableSlots(UUID carWashId,
                                                 VehicleType vehicleType,
                                                 ServiceType serviceType) {
        var price = priceRepository.findByCarWashIdAndVehicleTypeAndServiceType(
                carWashId, vehicleType, serviceType).orElse(null);
        if (price == null) return List.of();

        var idleBays = bayRepository.findByCarWashIdAndStatus(carWashId, BayStatus.IDLE);
        if (idleBays.isEmpty()) return List.of();

        var slots = new ArrayList<SlotResponse>();
        var now = OffsetDateTime.now();
        for (int i = 0; i < 8; i++) {
            var start = now.plusMinutes((long) i * price.getDurationMinutes());
            var end = start.plusMinutes(price.getDurationMinutes());
            var hasAvailableBay = idleBays.stream().anyMatch(b ->
                    bookingRepository.findOverlapping(b.getId(), start, end).isEmpty());
            if (hasAvailableBay) {
                slots.add(new SlotResponse(start, price.getDurationMinutes(), price.getAmountAmd()));
            }
        }
        return slots;
    }
}
