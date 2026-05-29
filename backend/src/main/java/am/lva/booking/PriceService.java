package am.lva.booking;

import am.lva.booking.dto.BulkPriceRequest;
import am.lva.booking.dto.PriceResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PriceService {

    private final PriceRepository priceRepository;
    private final CarWashRepository carWashRepository;

    @Transactional(readOnly = true)
    public List<PriceResponse> list(UUID carWashId) {
        return priceRepository.findByCarWashId(carWashId).stream()
                .map(PriceResponse::from).toList();
    }

    @Transactional
    public List<PriceResponse> bulkUpsert(UUID carWashId, BulkPriceRequest request) {
        var carWash = carWashRepository.findById(carWashId).orElseThrow();
        for (var entry : request.prices()) {
            var existing = priceRepository.findByCarWashIdAndVehicleTypeAndServiceType(
                    carWashId, entry.vehicleType(), entry.serviceType());
            if (existing.isPresent()) {
                var price = existing.get();
                price.setDurationMinutes(entry.durationMinutes());
                price.setAmountAmd(entry.amountAmd());
                priceRepository.save(price);
            } else {
                var price = new Price();
                price.setCarWash(carWash);
                price.setVehicleType(entry.vehicleType());
                price.setServiceType(entry.serviceType());
                price.setDurationMinutes(entry.durationMinutes());
                price.setAmountAmd(entry.amountAmd());
                priceRepository.save(price);
            }
        }
        return priceRepository.findByCarWashId(carWashId).stream()
                .map(PriceResponse::from).toList();
    }
}
