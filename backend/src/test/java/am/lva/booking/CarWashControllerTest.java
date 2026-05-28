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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class CarWashControllerTest extends BaseIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired AuthService authService;
    @Autowired UserRepository userRepository;
    @Autowired CarWashRepository carWashRepository;
    @Autowired BayRepository bayRepository;
    @Autowired VehicleRepository vehicleRepository;

    private String ownerToken;

    @BeforeEach
    void setup() {
        vehicleRepository.deleteAll();
        bayRepository.deleteAll();
        carWashRepository.deleteAll();
        userRepository.deleteAll();

        authService.register(new RegisterRequest("+37477900001", "pass"));
        var user = userRepository.findByPhone("+37477900001").orElseThrow();
        user.setRole(am.lva.auth.UserRole.OWNER);
        userRepository.save(user);
        ownerToken = authService.login(new LoginRequest("+37477900001", "pass")).token();
    }

    @Test
    void createAndListCarWash() throws Exception {
        var result = mockMvc.perform(post("/api/owner/car-washes")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"AutoSpa\",\"address\":\"Tigranyan 5\",\"lat\":40.18,\"lng\":44.51}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.name").value("AutoSpa"))
                .andReturn();

        mockMvc.perform(get("/api/owner/car-washes")
                        .header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("AutoSpa"));
    }

    @Test
    void createBayForCarWash() throws Exception {
        var washResult = mockMvc.perform(post("/api/owner/car-washes")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"AutoSpa\",\"address\":\"Tigranyan 5\",\"lat\":40.18,\"lng\":44.51}"))
                .andReturn();
        var carWashId = objectMapper.readTree(
                washResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(post("/api/owner/car-washes/" + carWashId + "/bays")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Bay 1\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Bay 1"))
                .andExpect(jsonPath("$.status").value("IDLE"));
    }

    @Test
    void publicListingShowsAvailabilityStatus() throws Exception {
        // Create car wash and bay via owner
        var washResult = mockMvc.perform(post("/api/owner/car-washes")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"TestWash\",\"address\":\"Addr 1\",\"lat\":40.19,\"lng\":44.52}"))
                .andReturn();
        var carWashId = objectMapper.readTree(
                washResult.getResponse().getContentAsString()).get("id").asText();
        mockMvc.perform(post("/api/owner/car-washes/" + carWashId + "/bays")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"Bay 1\"}"));

        // Register customer and hit public listing
        authService.register(new RegisterRequest("+37477900002", "pass"));
        var customerToken = authService.login(new LoginRequest("+37477900002", "pass")).token();

        mockMvc.perform(get("/api/client/car-washes")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].availabilityStatus").isNotEmpty());
    }
}
