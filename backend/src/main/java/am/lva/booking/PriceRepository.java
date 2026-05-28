package am.lva.booking;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PriceRepository extends JpaRepository<Price, UUID> {
    Optional<Price> findByCarWashIdAndVehicleTypeAndServiceType(
            UUID carWashId, VehicleType vehicleType, ServiceType serviceType);
}
