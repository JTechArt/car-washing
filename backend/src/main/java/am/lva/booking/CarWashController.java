package am.lva.booking;

import am.lva.booking.dto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class CarWashController {

    private final CarWashService carWashService;

    @PostMapping("/api/owner/car-washes")
    public CarWashResponse create(@Valid @RequestBody CarWashRequest request,
                                  @AuthenticationPrincipal UUID ownerId) {
        return carWashService.create(request, ownerId);
    }

    @GetMapping("/api/owner/car-washes")
    public List<CarWashResponse> list(@AuthenticationPrincipal UUID ownerId) {
        return carWashService.listByOwner(ownerId);
    }

    @PostMapping("/api/owner/car-washes/{carWashId}/bays")
    public BayResponse createBay(@PathVariable UUID carWashId,
                                 @Valid @RequestBody BayRequest request) {
        return carWashService.createBay(carWashId, request);
    }

    @GetMapping("/api/owner/car-washes/{carWashId}/bays")
    public List<BayResponse> listBays(@PathVariable UUID carWashId) {
        return carWashService.listBays(carWashId);
    }

    @GetMapping("/api/client/car-washes")
    public List<PublicCarWashResponse> publicListing() {
        return carWashService.getPublicListing();
    }
}
