package am.lva.booking;

import am.lva.booking.dto.BulkPriceRequest;
import am.lva.booking.dto.PriceResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/owner/car-washes/{carWashId}/prices")
@RequiredArgsConstructor
public class PriceController {

    private final PriceService priceService;

    @GetMapping
    public List<PriceResponse> list(@PathVariable UUID carWashId) {
        return priceService.list(carWashId);
    }

    @PutMapping
    public List<PriceResponse> bulkUpsert(@PathVariable UUID carWashId,
                                           @Valid @RequestBody BulkPriceRequest request) {
        return priceService.bulkUpsert(carWashId, request);
    }
}
