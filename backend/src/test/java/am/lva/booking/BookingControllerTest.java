package am.lva.booking;

import am.lva.BaseIntegrationTest;
import am.lva.auth.AuthService;
import am.lva.auth.UserRepository;
import am.lva.auth.dto.LoginRequest;
import am.lva.auth.dto.RegisterRequest;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class BookingControllerTest extends BaseIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired AuthService authService;
    @Autowired UserRepository userRepository;
    @Autowired CarWashRepository carWashRepository;
    @Autowired BayRepository bayRepository;
    @Autowired PriceRepository priceRepository;
    @Autowired BookingRepository bookingRepository;
    @Autowired WalkInRepository walkInRepository;
    @Autowired VehicleRepository vehicleRepository;

    private String customerToken;
    private String moderatorToken;
    private CarWash carWash;
    private Bay bay;

    @BeforeEach
    void setup() {
        walkInRepository.deleteAll();
        bookingRepository.deleteAll();
        vehicleRepository.deleteAll();
        priceRepository.deleteAll();
        bayRepository.deleteAll();
        carWashRepository.deleteAll();
        userRepository.deleteAll();

        authService.register(new RegisterRequest("+37477600001", "pass"));
        var owner = userRepository.findByPhone("+37477600001").orElseThrow();
        owner.setRole(am.lva.auth.UserRole.OWNER);
        userRepository.save(owner);

        authService.register(new RegisterRequest("+37477600002", "pass"));
        var mod = userRepository.findByPhone("+37477600002").orElseThrow();
        mod.setRole(am.lva.auth.UserRole.MODERATOR);
        userRepository.save(mod);
        moderatorToken = authService.login(new LoginRequest("+37477600002", "pass")).token();

        authService.register(new RegisterRequest("+37477600003", "pass"));
        customerToken = authService.login(new LoginRequest("+37477600003", "pass")).token();

        carWash = new CarWash();
        carWash.setName("Test Wash");
        carWash.setAddress("Addr");
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
    void createBooking() throws Exception {
        var vehicleResult = mockMvc.perform(post("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"plate\":\"AM1234AB\",\"type\":\"SEDAN\"}"))
                .andReturn();
        var vehicleId = objectMapper.readTree(
                vehicleResult.getResponse().getContentAsString()).get("id").asText();

        var slotStart = OffsetDateTime.now().plusMinutes(10)
                .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        var body = String.format(
                "{\"carWashId\":\"%s\",\"vehicleId\":\"%s\",\"serviceType\":\"EXTERIOR\",\"slotStartsAt\":\"%s\"}",
                carWash.getId(), vehicleId, slotStart);

        mockMvc.perform(post("/api/client/bookings")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.status").value("PENDING"));
    }

    @Test
    void moderatorUpdatesBookingStatus() throws Exception {
        // Create vehicle and booking
        var vehicleResult = mockMvc.perform(post("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"plate\":\"AM5678CD\",\"type\":\"SEDAN\"}"))
                .andReturn();
        var vehicleId = objectMapper.readTree(
                vehicleResult.getResponse().getContentAsString()).get("id").asText();

        var slotStart = OffsetDateTime.now().plusMinutes(5)
                .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        var bookingBody = String.format(
                "{\"carWashId\":\"%s\",\"vehicleId\":\"%s\",\"serviceType\":\"EXTERIOR\",\"slotStartsAt\":\"%s\"}",
                carWash.getId(), vehicleId, slotStart);
        var bookingResult = mockMvc.perform(post("/api/client/bookings")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON).content(bookingBody))
                .andReturn();
        var bookingId = objectMapper.readTree(
                bookingResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(put("/api/moderator/bookings/" + bookingId + "/status")
                        .header("Authorization", "Bearer " + moderatorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"ARRIVED\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ARRIVED"));
    }

    @Test
    void walkInBlocksBay() throws Exception {
        mockMvc.perform(post("/api/moderator/bays/" + bay.getId() + "/walk-ins")
                        .header("Authorization", "Bearer " + moderatorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estimatedDurationMinutes\":30}"))
                .andExpect(status().isOk());

        var updated = bayRepository.findById(bay.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(BayStatus.OCCUPIED);
    }
}
