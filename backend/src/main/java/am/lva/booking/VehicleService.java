package am.lva.booking;

import am.lva.auth.UserRepository;
import am.lva.booking.dto.VehicleRequest;
import am.lva.booking.dto.VehicleResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final UserRepository userRepository;

    public VehicleResponse add(VehicleRequest request, UUID userId) {
        var user = userRepository.findById(userId).orElseThrow();
        var vehicle = new Vehicle();
        vehicle.setUser(user);
        vehicle.setPlate(request.plate());
        vehicle.setType(request.type());
        vehicle.setNickname(request.nickname());
        return VehicleResponse.from(vehicleRepository.save(vehicle));
    }

    public List<VehicleResponse> list(UUID userId) {
        var user = userRepository.findById(userId).orElseThrow();
        return vehicleRepository.findByUser(user).stream()
                .map(VehicleResponse::from).toList();
    }
}
