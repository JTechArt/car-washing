package am.lva.booking;

import am.lva.BaseIntegrationTest;
import am.lva.auth.AuthService;
import am.lva.auth.UserRepository;
import am.lva.auth.dto.RegisterRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

class SlotServiceTest extends BaseIntegrationTest {

    @Autowired SlotService slotService;
    @Autowired CarWashRepository carWashRepository;
    @Autowired BayRepository bayRepository;
    @Autowired PriceRepository priceRepository;
    @Autowired BookingRepository bookingRepository;
    @Autowired WalkInRepository walkInRepository;
    @Autowired AuthService authService;
    @Autowired UserRepository userRepository;
    @Autowired VehicleRepository vehicleRepository;

    private CarWash carWash;
    private Bay bay;

    @BeforeEach
    void setup() {
        walkInRepository.deleteAll();
        bookingRepository.deleteAll();
        vehicleRepository.deleteAll();
        bayRepository.deleteAll();
        priceRepository.deleteAll();
        carWashRepository.deleteAll();
        userRepository.deleteAll();

        authService.register(new RegisterRequest("+37477700001", "pass"));
        var owner = userRepository.findByPhone("+37477700001").orElseThrow();
        owner.setRole(am.lva.auth.UserRole.OWNER);
        userRepository.save(owner);

        carWash = new CarWash();
        carWash.setName("Test Wash");
        carWash.setAddress("Test Addr");
        carWash.setLat(40.18);
        carWash.setLng(44.51);
        carWash.setOwner(owner);
        carWashRepository.save(carWash);

        bay = new Bay();
        bay.setCarWash(carWash);
        bay.setName("Bay 1");
        bay.setStatus(BayStatus.IDLE);
        bayRepository.save(bay);

        var price = new Price();
        price.setCarWash(carWash);
        price.setVehicleType(VehicleType.SEDAN);
        price.setServiceType(ServiceType.EXTERIOR);
        price.setDurationMinutes(25);
        price.setAmountAmd(3500);
        priceRepository.save(price);
    }

    @Test
    void availableSlotsReturnedWhenBayIdle() {
        var slots = slotService.getAvailableSlots(
                carWash.getId(), VehicleType.SEDAN, ServiceType.EXTERIOR);
        assertThat(slots).isNotEmpty();
        assertThat(slots.get(0).durationMinutes()).isEqualTo(25);
        assertThat(slots.get(0).amountAmd()).isEqualTo(3500);
    }

    @Test
    void noSlotsWhenBayOccupied() {
        bay.setStatus(BayStatus.OCCUPIED);
        bayRepository.save(bay);

        var slots = slotService.getAvailableSlots(
                carWash.getId(), VehicleType.SEDAN, ServiceType.EXTERIOR);
        assertThat(slots).isEmpty();
    }

    @Test
    void noSlotsWhenNoPriceConfigured() {
        var slots = slotService.getAvailableSlots(
                carWash.getId(), VehicleType.SUV, ServiceType.FULL);
        assertThat(slots).isEmpty();
    }
}
