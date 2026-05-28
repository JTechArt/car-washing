package am.lva.booking;

import am.lva.BaseIntegrationTest;
import am.lva.auth.AuthService;
import am.lva.auth.UserRepository;
import am.lva.auth.dto.LoginRequest;
import am.lva.auth.dto.RegisterRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class VehicleControllerTest extends BaseIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired AuthService authService;
    @Autowired UserRepository userRepository;
    @Autowired VehicleRepository vehicleRepository;

    private String customerToken;

    @BeforeEach
    void setup() {
        vehicleRepository.deleteAll();
        userRepository.deleteAll();
        authService.register(new RegisterRequest("+37477800001", "pass"));
        customerToken = authService.login(new LoginRequest("+37477800001", "pass")).token();
    }

    @Test
    void addAndListVehicle() throws Exception {
        mockMvc.perform(post("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"plate\":\"AM1234AB\",\"type\":\"SEDAN\",\"nickname\":\"My Car\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.plate").value("AM1234AB"))
                .andExpect(jsonPath("$.type").value("SEDAN"))
                .andExpect(jsonPath("$.nickname").value("My Car"));

        mockMvc.perform(get("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].plate").value("AM1234AB"));
    }

    @Test
    void addMultipleVehicles() throws Exception {
        mockMvc.perform(post("/api/client/vehicles")
                .header("Authorization", "Bearer " + customerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"plate\":\"AM1111AA\",\"type\":\"SEDAN\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/client/vehicles")
                .header("Authorization", "Bearer " + customerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"plate\":\"AM2222BB\",\"type\":\"SUV\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }
}
