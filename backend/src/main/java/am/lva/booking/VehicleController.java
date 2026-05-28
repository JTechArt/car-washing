package am.lva.booking;

import am.lva.booking.dto.VehicleRequest;
import am.lva.booking.dto.VehicleResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/client/vehicles")
@RequiredArgsConstructor
public class VehicleController {

    private final VehicleService vehicleService;

    @PostMapping
    public VehicleResponse add(@Valid @RequestBody VehicleRequest request,
                               @AuthenticationPrincipal UUID userId) {
        return vehicleService.add(request, userId);
    }

    @GetMapping
    public List<VehicleResponse> list(@AuthenticationPrincipal UUID userId) {
        return vehicleService.list(userId);
    }
}
