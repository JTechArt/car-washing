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
public class BookingController {

    private final BookingService bookingService;
    private final SlotService slotService;

    @GetMapping("/api/client/car-washes/{carWashId}/slots")
    public List<SlotResponse> getSlots(@PathVariable UUID carWashId,
                                       @RequestParam VehicleType vehicleType,
                                       @RequestParam ServiceType serviceType) {
        return slotService.getAvailableSlots(carWashId, vehicleType, serviceType);
    }

    @GetMapping("/api/client/bookings")
    public List<BookingListResponse> myBookings(@AuthenticationPrincipal UUID userId) {
        return bookingService.getMyBookings(userId);
    }

    @PostMapping("/api/client/bookings")
    public BookingResponse createBooking(@Valid @RequestBody BookingRequest request,
                                         @AuthenticationPrincipal UUID userId) {
        return bookingService.create(request, userId);
    }

    @PutMapping("/api/moderator/bookings/{bookingId}/status")
    public BookingResponse updateStatus(@PathVariable UUID bookingId,
                                        @Valid @RequestBody StatusUpdateRequest request) {
        return bookingService.updateStatus(bookingId, request);
    }

    @PostMapping("/api/moderator/bays/{bayId}/walk-ins")
    public void walkIn(@PathVariable UUID bayId,
                       @Valid @RequestBody WalkInRequest request) {
        bookingService.createWalkIn(bayId, request);
    }
}
