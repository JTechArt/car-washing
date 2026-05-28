package am.lva.booking;

import am.lva.auth.UserRepository;
import am.lva.booking.dto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CarWashService {

    private final CarWashRepository carWashRepository;
    private final BayRepository bayRepository;
    private final UserRepository userRepository;

    public CarWashResponse create(CarWashRequest request, UUID ownerId) {
        var owner = userRepository.findById(ownerId).orElseThrow();
        var wash = new CarWash();
        wash.setName(request.name());
        wash.setAddress(request.address());
        wash.setLat(request.lat());
        wash.setLng(request.lng());
        wash.setOwner(owner);
        return CarWashResponse.from(carWashRepository.save(wash));
    }

    public List<CarWashResponse> listByOwner(UUID ownerId) {
        var owner = userRepository.findById(ownerId).orElseThrow();
        return carWashRepository.findByOwner(owner).stream()
                .map(CarWashResponse::from).toList();
    }

    public BayResponse createBay(UUID carWashId, BayRequest request) {
        var wash = carWashRepository.findById(carWashId).orElseThrow();
        var bay = new Bay();
        bay.setCarWash(wash);
        bay.setName(request.name());
        bay.setStatus(BayStatus.IDLE);
        return BayResponse.from(bayRepository.save(bay));
    }

    public List<BayResponse> listBays(UUID carWashId) {
        return bayRepository.findByCarWashId(carWashId).stream()
                .map(BayResponse::from).toList();
    }

    public List<PublicCarWashResponse> getPublicListing() {
        return carWashRepository.findAll().stream().map(wash -> {
            var bays = bayRepository.findByCarWashId(wash.getId());
            var idleCount = bays.stream().filter(b -> b.getStatus() == BayStatus.IDLE).count();
            AvailabilityStatus status;
            int nextSlotMinutes;
            if (idleCount > 0) {
                status = AvailabilityStatus.GREEN;
                nextSlotMinutes = 0;
            } else {
                status = AvailabilityStatus.RED;
                nextSlotMinutes = 60;
            }
            return new PublicCarWashResponse(
                    wash.getId(), wash.getName(), wash.getLat(), wash.getLng(),
                    status, nextSlotMinutes);
        }).toList();
    }
}
