package am.lva.booking;

import am.lva.auth.UserRepository;
import am.lva.booking.dto.*;
import am.lva.notifications.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final BayRepository bayRepository;
    private final VehicleRepository vehicleRepository;
    private final PriceRepository priceRepository;
    private final WalkInRepository walkInRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    @Transactional
    public BookingResponse create(BookingRequest request, UUID userId) {
        var vehicle = vehicleRepository.findById(request.vehicleId()).orElseThrow();
        var serviceType = ServiceType.valueOf(request.serviceType());
        var price = priceRepository.findByCarWashIdAndVehicleTypeAndServiceType(
                request.carWashId(), vehicle.getType(), serviceType).orElseThrow();

        var start = request.slotStartsAt();
        var end = start.plusMinutes(price.getDurationMinutes());

        var bay = bayRepository.findByCarWashIdAndStatus(request.carWashId(), BayStatus.IDLE)
                .stream()
                .filter(b -> bookingRepository.findOverlapping(b.getId(), start, end).isEmpty())
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("No available bay for requested slot"));

        var user = userRepository.findById(userId).orElseThrow();
        var booking = new Booking();
        booking.setBay(bay);
        booking.setUser(user);
        booking.setVehicle(vehicle);
        booking.setServiceType(serviceType);
        booking.setStartsAt(start);
        booking.setEndsAt(end);
        booking.setStatus(BookingStatus.PENDING);
        bookingRepository.save(booking);

        notificationService.broadcastBayStatus(
                bay.getCarWash().getId(), bay.getId(), bay.getStatus());
        return BookingResponse.from(booking);
    }

    @Transactional
    public BookingResponse updateStatus(UUID bookingId, StatusUpdateRequest request) {
        var booking = bookingRepository.findById(bookingId).orElseThrow();
        booking.setStatus(request.status());
        var bay = booking.getBay();
        if (request.status() == BookingStatus.COMPLETED
                || request.status() == BookingStatus.CANCELLED) {
            bay.setStatus(BayStatus.IDLE);
        } else {
            bay.setStatus(BayStatus.OCCUPIED);
        }
        bayRepository.save(bay);
        bookingRepository.save(booking);
        notificationService.broadcastBayStatus(
                bay.getCarWash().getId(), bay.getId(), bay.getStatus());
        return BookingResponse.from(booking);
    }

    @Transactional
    public void createWalkIn(UUID bayId, WalkInRequest request) {
        var bay = bayRepository.findById(bayId).orElseThrow();
        var walkIn = new WalkIn();
        walkIn.setBay(bay);
        walkIn.setStartsAt(OffsetDateTime.now());
        walkIn.setEndsAt(OffsetDateTime.now().plusMinutes(request.estimatedDurationMinutes()));
        walkInRepository.save(walkIn);
        bay.setStatus(BayStatus.OCCUPIED);
        bayRepository.save(bay);
        notificationService.broadcastBayStatus(
                bay.getCarWash().getId(), bay.getId(), bay.getStatus());
    }
}
