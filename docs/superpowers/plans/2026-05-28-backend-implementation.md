# Lva Backend — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Lva backend MVP core — auth, multi-tenancy, car wash & bay management, booking engine, vehicle garage, and real-time WebSocket notifications.

**Architecture:** Spring Boot 3.2 modular monolith. Six packages (auth, tenancy, booking, notifications, payments, analytics) share one PostgreSQL database and JVM. All tenant-scoped entities carry a nullable `tenant_id` column filtered via Hibernate. WebSocket (STOMP) broadcasts bay status changes within ≤1.5s.

**Tech Stack:** Java 21, Spring Boot 3.2.5, PostgreSQL 16, Flyway, JJWT 0.12.5, Spring Security, STOMP WebSockets, Testcontainers (for integration tests), JUnit 5, MockMvc

---

## File Map

```
backend/
├── pom.xml                                                    (modify: add testcontainers)
├── src/
│   ├── main/
│   │   ├── java/am/lva/
│   │   │   ├── LvaApplication.java                           (exists)
│   │   │   ├── auth/
│   │   │   │   ├── UserRole.java                             (create: enum)
│   │   │   │   ├── User.java                                 (create: @Entity)
│   │   │   │   ├── UserRepository.java                       (create)
│   │   │   │   ├── JwtService.java                           (create)
│   │   │   │   ├── JwtAuthFilter.java                        (create)
│   │   │   │   ├── AuthService.java                          (create)
│   │   │   │   ├── AuthController.java                       (create)
│   │   │   │   ├── SecurityConfig.java                       (create)
│   │   │   │   └── dto/
│   │   │   │       ├── RegisterRequest.java                  (create: record)
│   │   │   │       ├── LoginRequest.java                     (create: record)
│   │   │   │       └── AuthResponse.java                     (create: record)
│   │   │   ├── tenancy/
│   │   │   │   ├── TenantContext.java                        (create: ThreadLocal)
│   │   │   │   ├── TenantInterceptor.java                    (create)
│   │   │   │   └── TenantConfig.java                         (create)
│   │   │   ├── booking/
│   │   │   │   ├── BayStatus.java                            (create: enum)
│   │   │   │   ├── BookingStatus.java                        (create: enum)
│   │   │   │   ├── VehicleType.java                          (create: enum)
│   │   │   │   ├── ServiceType.java                          (create: enum)
│   │   │   │   ├── AvailabilityStatus.java                   (create: enum)
│   │   │   │   ├── CarWash.java                              (create: @Entity)
│   │   │   │   ├── CarWashRepository.java                    (create)
│   │   │   │   ├── Bay.java                                  (create: @Entity)
│   │   │   │   ├── BayRepository.java                        (create)
│   │   │   │   ├── Price.java                                (create: @Entity)
│   │   │   │   ├── PriceRepository.java                      (create)
│   │   │   │   ├── Vehicle.java                              (create: @Entity)
│   │   │   │   ├── VehicleRepository.java                    (create)
│   │   │   │   ├── Booking.java                              (create: @Entity)
│   │   │   │   ├── BookingRepository.java                    (create)
│   │   │   │   ├── WalkIn.java                               (create: @Entity)
│   │   │   │   ├── WalkInRepository.java                     (create)
│   │   │   │   ├── CarWashService.java                       (create)
│   │   │   │   ├── VehicleService.java                       (create)
│   │   │   │   ├── SlotService.java                          (create)
│   │   │   │   ├── BookingService.java                       (create)
│   │   │   │   ├── CarWashController.java                    (create)
│   │   │   │   ├── VehicleController.java                    (create)
│   │   │   │   ├── BookingController.java                    (create)
│   │   │   │   └── dto/
│   │   │   │       ├── CarWashRequest.java                   (create: record)
│   │   │   │       ├── CarWashResponse.java                  (create: record)
│   │   │   │       ├── PublicCarWashResponse.java            (create: record)
│   │   │   │       ├── BayRequest.java                       (create: record)
│   │   │   │       ├── BayResponse.java                      (create: record)
│   │   │   │       ├── VehicleRequest.java                   (create: record)
│   │   │   │       ├── VehicleResponse.java                  (create: record)
│   │   │   │       ├── SlotResponse.java                     (create: record)
│   │   │   │       ├── BookingRequest.java                   (create: record)
│   │   │   │       ├── BookingResponse.java                  (create: record)
│   │   │   │       ├── WalkInRequest.java                    (create: record)
│   │   │   │       └── StatusUpdateRequest.java              (create: record)
│   │   │   └── notifications/
│   │   │       ├── WebSocketConfig.java                      (create)
│   │   │       ├── BayStatusMessage.java                     (create: record)
│   │   │       └── NotificationService.java                  (create)
│   │   └── resources/
│   │       ├── application.yml                               (exists)
│   │       ├── application-test.yml                          (create)
│   │       └── db/migration/
│   │           └── V1__baseline.sql                          (create)
│   └── test/
│       └── java/am/lva/
│           ├── BaseIntegrationTest.java                      (create)
│           ├── auth/
│           │   └── AuthControllerTest.java                   (create)
│           ├── tenancy/
│           │   └── TenantContextTest.java                    (create)
│           ├── booking/
│           │   ├── CarWashControllerTest.java                (create)
│           │   ├── VehicleControllerTest.java                (create)
│           │   ├── SlotServiceTest.java                      (create)
│           │   └── BookingControllerTest.java                (create)
│           └── notifications/
│               └── NotificationServiceTest.java              (create)
```

---

## Task 1: Test Infrastructure + Flyway Migration

**Files:**
- Modify: `backend/pom.xml`
- Create: `backend/src/main/resources/db/migration/V1__baseline.sql`
- Create: `backend/src/main/resources/application-test.yml`
- Create: `backend/src/test/java/am/lva/BaseIntegrationTest.java`

- [ ] **Step 1: Add Testcontainers to pom.xml**

Add inside `<dependencies>` in `backend/pom.xml`:

```xml
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>junit-jupiter</artifactId>
  <version>1.19.8</version>
  <scope>test</scope>
</dependency>
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>postgresql</artifactId>
  <version>1.19.8</version>
  <scope>test</scope>
</dependency>
```

- [ ] **Step 2: Create V1__baseline.sql**

Create `backend/src/main/resources/db/migration/V1__baseline.sql`:

```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  logo_url TEXT,
  theme_color VARCHAR(7),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255),
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('CUSTOMER','MODERATOR','OWNER','SUPER_ADMIN')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE car_washes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  name VARCHAR(255) NOT NULL,
  address TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE bays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  car_wash_id UUID NOT NULL REFERENCES car_washes(id),
  name VARCHAR(100) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'IDLE' CHECK (status IN ('IDLE','OCCUPIED','BLOCKED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  plate VARCHAR(20) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('SEDAN','CROSSOVER','SUV','COUPE')),
  nickname VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  car_wash_id UUID NOT NULL REFERENCES car_washes(id),
  vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('SEDAN','CROSSOVER','SUV','COUPE')),
  service_type VARCHAR(50) NOT NULL,
  duration_minutes INT NOT NULL,
  amount_amd INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (car_wash_id, vehicle_type, service_type)
);

CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  bay_id UUID NOT NULL REFERENCES bays(id),
  user_id UUID NOT NULL REFERENCES users(id),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  service_type VARCHAR(50) NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ARRIVED','WASHING','FINISHING','COMPLETED','CANCELLED')),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID','PAID','REFUNDED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE walk_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  bay_id UUID NOT NULL REFERENCES bays(id),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  plan_id VARCHAR(50) NOT NULL,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_to TIMESTAMPTZ NOT NULL,
  washes_remaining INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE corporate_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  company_name VARCHAR(255) NOT NULL,
  billing_cycle VARCHAR(20) NOT NULL CHECK (billing_cycle IN ('MONTHLY','QUARTERLY')),
  balance_amd INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_bookings_bay_time ON bookings(bay_id, starts_at, ends_at);
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bays_car_wash ON bays(car_wash_id);
CREATE INDEX idx_car_washes_location ON car_washes(lat, lng);
```

- [ ] **Step 3: Create application-test.yml**

Create `backend/src/main/resources/application-test.yml`:

```yaml
spring:
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: validate
  flyway:
    enabled: true

lva:
  jwt:
    secret: test-secret-key-for-testing-only-32c
    expiry-ms: 3600000
```

- [ ] **Step 4: Create BaseIntegrationTest**

Create `backend/src/test/java/am/lva/BaseIntegrationTest.java`:

```java
package am.lva;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Testcontainers
public abstract class BaseIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("lva_test")
            .withUsername("lva")
            .withPassword("lva");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

- [ ] **Step 5: Write a smoke test to verify Flyway runs**

Create `backend/src/test/java/am/lva/FlywayMigrationTest.java`:

```java
package am.lva;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import javax.sql.DataSource;
import java.sql.Connection;

import static org.assertj.core.api.Assertions.assertThatCode;

class FlywayMigrationTest extends BaseIntegrationTest {

    @Autowired
    DataSource dataSource;

    @Test
    void allTablesCreated() throws Exception {
        try (Connection conn = dataSource.getConnection()) {
            var tables = new String[]{"tenants","users","car_washes","bays",
                    "vehicles","bookings","walk_ins","prices","subscriptions","corporate_accounts"};
            for (String table : tables) {
                var rs = conn.getMetaData().getTables(null, null, table, null);
                assertThatCode(() -> {}).doesNotThrowAnyException();
                var exists = rs.next();
                org.assertj.core.api.Assertions.assertThat(exists)
                        .as("Table %s must exist", table).isTrue();
            }
        }
    }
}
```

- [ ] **Step 6: Run test to verify it passes**

```bash
cd backend && ./mvnw test -pl . -Dtest=FlywayMigrationTest -q
```

Expected output: `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 7: Commit**

```bash
git add backend/pom.xml backend/src/main/resources/db/migration/V1__baseline.sql \
        backend/src/main/resources/application-test.yml \
        backend/src/test/java/am/lva/
git commit -m "feat: add Flyway migration baseline and test infrastructure"
```

---

## Task 2: JWT Service

**Files:**
- Create: `backend/src/main/java/am/lva/auth/JwtService.java`
- Create: `backend/src/test/java/am/lva/auth/JwtServiceTest.java`

- [ ] **Step 1: Write failing test**

Create `backend/src/test/java/am/lva/auth/JwtServiceTest.java`:

```java
package am.lva.auth;

import am.lva.BaseIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest extends BaseIntegrationTest {

    @Autowired
    JwtService jwtService;

    @Test
    void generateAndValidateToken() {
        var userId = UUID.randomUUID();
        var token = jwtService.generateToken(userId, UserRole.CUSTOMER, null);

        assertThat(token).isNotBlank();
        assertThat(jwtService.extractUserId(token)).isEqualTo(userId);
        assertThat(jwtService.extractRole(token)).isEqualTo(UserRole.CUSTOMER);
        assertThat(jwtService.extractTenantId(token)).isNull();
    }

    @Test
    void tokenWithTenantId() {
        var userId = UUID.randomUUID();
        var tenantId = UUID.randomUUID();
        var token = jwtService.generateToken(userId, UserRole.OWNER, tenantId);

        assertThat(jwtService.extractTenantId(token)).isEqualTo(tenantId);
    }

    @Test
    void invalidTokenThrows() {
        assertThatThrownBy(() -> jwtService.extractUserId("bad.token.here"))
                .isInstanceOf(Exception.class);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd backend && ./mvnw test -Dtest=JwtServiceTest -q 2>&1 | tail -5
```

Expected: `FAILURE` — JwtService not found.

- [ ] **Step 3: Create UserRole enum**

Create `backend/src/main/java/am/lva/auth/UserRole.java`:

```java
package am.lva.auth;

public enum UserRole {
    CUSTOMER, MODERATOR, OWNER, SUPER_ADMIN
}
```

- [ ] **Step 4: Create JwtService**

Create `backend/src/main/java/am/lva/auth/JwtService.java`:

```java
package am.lva.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    private final SecretKey key;
    private final long expiryMs;

    public JwtService(
            @Value("${lva.jwt.secret}") String secret,
            @Value("${lva.jwt.expiry-ms}") long expiryMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expiryMs = expiryMs;
    }

    public String generateToken(UUID userId, UserRole role, UUID tenantId) {
        var builder = Jwts.builder()
                .subject(userId.toString())
                .claim("role", role.name())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiryMs))
                .signWith(key);
        if (tenantId != null) {
            builder.claim("tenantId", tenantId.toString());
        }
        return builder.compact();
    }

    public UUID extractUserId(String token) {
        return UUID.fromString(parseClaims(token).getSubject());
    }

    public UserRole extractRole(String token) {
        return UserRole.valueOf(parseClaims(token).get("role", String.class));
    }

    public UUID extractTenantId(String token) {
        String tenantId = parseClaims(token).get("tenantId", String.class);
        return tenantId != null ? UUID.fromString(tenantId) : null;
    }

    public boolean isTokenValid(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private Claims parseClaims(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd backend && ./mvnw test -Dtest=JwtServiceTest -q 2>&1 | tail -5
```

Expected: `Tests run: 3, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/am/lva/auth/ backend/src/test/java/am/lva/auth/JwtServiceTest.java
git commit -m "feat: add UserRole enum and JwtService with token generation/validation"
```

---

## Task 3: User Entity + Auth Endpoints

**Files:**
- Create: `backend/src/main/java/am/lva/auth/User.java`
- Create: `backend/src/main/java/am/lva/auth/UserRepository.java`
- Create: `backend/src/main/java/am/lva/auth/dto/RegisterRequest.java`
- Create: `backend/src/main/java/am/lva/auth/dto/LoginRequest.java`
- Create: `backend/src/main/java/am/lva/auth/dto/AuthResponse.java`
- Create: `backend/src/main/java/am/lva/auth/AuthService.java`
- Create: `backend/src/main/java/am/lva/auth/AuthController.java`
- Create: `backend/src/main/java/am/lva/auth/JwtAuthFilter.java`
- Create: `backend/src/main/java/am/lva/auth/SecurityConfig.java`
- Create: `backend/src/test/java/am/lva/auth/AuthControllerTest.java`

- [ ] **Step 1: Write failing tests**

Create `backend/src/test/java/am/lva/auth/AuthControllerTest.java`:

```java
package am.lva.auth;

import am.lva.BaseIntegrationTest;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class AuthControllerTest extends BaseIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;

    @BeforeEach
    void cleanup() {
        userRepository.deleteAll();
    }

    @Test
    void registerAndLogin() throws Exception {
        // Register
        var registerBody = """
                {"phone":"+37477123456","password":"secret123"}
                """;
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.role").value("CUSTOMER"));

        // Login
        var loginBody = """
                {"phone":"+37477123456","password":"secret123"}
                """;
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());
    }

    @Test
    void duplicatePhoneReturns409() throws Exception {
        var body = """
                {"phone":"+37477111111","password":"secret123"}
                """;
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isConflict());
    }

    @Test
    void wrongPasswordReturns401() throws Exception {
        var register = """
                {"phone":"+37477222222","password":"correct"}
                """;
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON).content(register))
                .andExpect(status().isOk());

        var login = """
                {"phone":"+37477222222","password":"wrong"}
                """;
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON).content(login))
                .andExpect(status().isUnauthorized());
    }
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd backend && ./mvnw test -Dtest=AuthControllerTest -q 2>&1 | tail -5
```

Expected: FAILURE — `AuthController` not found.

- [ ] **Step 3: Create User entity**

Create `backend/src/main/java/am/lva/auth/User.java`:

```java
package am.lva.auth;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Column(unique = true, nullable = false)
    private String phone;

    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    @CreationTimestamp
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
}
```

- [ ] **Step 4: Create UserRepository**

Create `backend/src/main/java/am/lva/auth/UserRepository.java`:

```java
package am.lva.auth;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByPhone(String phone);
    boolean existsByPhone(String phone);
}
```

- [ ] **Step 5: Create DTOs**

Create `backend/src/main/java/am/lva/auth/dto/RegisterRequest.java`:

```java
package am.lva.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record RegisterRequest(
        @NotBlank String phone,
        @NotBlank String password
) {}
```

Create `backend/src/main/java/am/lva/auth/dto/LoginRequest.java`:

```java
package am.lva.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank String phone,
        @NotBlank String password
) {}
```

Create `backend/src/main/java/am/lva/auth/dto/AuthResponse.java`:

```java
package am.lva.auth.dto;

import am.lva.auth.UserRole;

public record AuthResponse(String token, UserRole role) {}
```

- [ ] **Step 6: Create AuthService**

Create `backend/src/main/java/am/lva/auth/AuthService.java`:

```java
package am.lva.auth;

import am.lva.auth.dto.AuthResponse;
import am.lva.auth.dto.LoginRequest;
import am.lva.auth.dto.RegisterRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByPhone(request.phone())) {
            throw new PhoneAlreadyRegisteredException(request.phone());
        }
        var user = new User();
        user.setPhone(request.phone());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(UserRole.CUSTOMER);
        userRepository.save(user);
        var token = jwtService.generateToken(user.getId(), user.getRole(), user.getTenantId());
        return new AuthResponse(token, user.getRole());
    }

    public AuthResponse login(LoginRequest request) {
        var user = userRepository.findByPhone(request.phone())
                .orElseThrow(InvalidCredentialsException::new);
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new InvalidCredentialsException();
        }
        var token = jwtService.generateToken(user.getId(), user.getRole(), user.getTenantId());
        return new AuthResponse(token, user.getRole());
    }
}
```

- [ ] **Step 7: Create domain exceptions**

Create `backend/src/main/java/am/lva/auth/PhoneAlreadyRegisteredException.java`:

```java
package am.lva.auth;

public class PhoneAlreadyRegisteredException extends RuntimeException {
    public PhoneAlreadyRegisteredException(String phone) {
        super("Phone already registered: " + phone);
    }
}
```

Create `backend/src/main/java/am/lva/auth/InvalidCredentialsException.java`:

```java
package am.lva.auth;

public class InvalidCredentialsException extends RuntimeException {
    public InvalidCredentialsException() {
        super("Invalid credentials");
    }
}
```

- [ ] **Step 8: Create AuthController**

Create `backend/src/main/java/am/lva/auth/AuthController.java`:

```java
package am.lva.auth;

import am.lva.auth.dto.AuthResponse;
import am.lva.auth.dto.LoginRequest;
import am.lva.auth.dto.RegisterRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @ExceptionHandler(PhoneAlreadyRegisteredException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public String handleDuplicate(PhoneAlreadyRegisteredException ex) {
        return ex.getMessage();
    }

    @ExceptionHandler(InvalidCredentialsException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public String handleInvalidCreds(InvalidCredentialsException ex) {
        return ex.getMessage();
    }
}
```

- [ ] **Step 9: Create JwtAuthFilter**

Create `backend/src/main/java/am/lva/auth/JwtAuthFilter.java`:

```java
package am.lva.auth;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        var authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            var token = authHeader.substring(7);
            if (jwtService.isTokenValid(token)) {
                var userId = jwtService.extractUserId(token);
                var role = jwtService.extractRole(token);
                var auth = new UsernamePasswordAuthenticationToken(
                        userId, token,
                        List.of(new SimpleGrantedAuthority("ROLE_" + role.name()))
                );
                SecurityContextHolder.getContext().setAuthentication(auth);
            }
        }
        filterChain.doFilter(request, response);
    }
}
```

- [ ] **Step 10: Create SecurityConfig**

Create `backend/src/main/java/am/lva/auth/SecurityConfig.java`:

```java
package am.lva.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**").permitAll()
                        .requestMatchers("/api/superadmin/**").hasRole("SUPER_ADMIN")
                        .requestMatchers("/api/owner/**").hasAnyRole("OWNER", "SUPER_ADMIN")
                        .requestMatchers("/api/moderator/**").hasAnyRole("MODERATOR", "OWNER", "SUPER_ADMIN")
                        .requestMatchers("/api/client/**").authenticated()
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

- [ ] **Step 11: Run tests to verify they pass**

```bash
cd backend && ./mvnw test -Dtest=AuthControllerTest -q 2>&1 | tail -5
```

Expected: `Tests run: 3, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 12: Commit**

```bash
git add backend/src/
git commit -m "feat: add User entity, JWT auth filter, register/login endpoints"
```

---

## Task 4: TenantContext + Interceptor

**Files:**
- Create: `backend/src/main/java/am/lva/tenancy/TenantContext.java`
- Create: `backend/src/main/java/am/lva/tenancy/TenantInterceptor.java`
- Create: `backend/src/main/java/am/lva/tenancy/TenantConfig.java`
- Create: `backend/src/test/java/am/lva/tenancy/TenantContextTest.java`

- [ ] **Step 1: Write failing test**

Create `backend/src/test/java/am/lva/tenancy/TenantContextTest.java`:

```java
package am.lva.tenancy;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class TenantContextTest {

    @AfterEach
    void cleanup() {
        TenantContext.clear();
    }

    @Test
    void setAndGet() {
        var id = UUID.randomUUID();
        TenantContext.set(id);
        assertThat(TenantContext.get()).isEqualTo(id);
    }

    @Test
    void clearReturnsNull() {
        TenantContext.set(UUID.randomUUID());
        TenantContext.clear();
        assertThat(TenantContext.get()).isNull();
    }

    @Test
    void defaultIsNull() {
        assertThat(TenantContext.get()).isNull();
    }
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd backend && ./mvnw test -Dtest=TenantContextTest -q 2>&1 | tail -5
```

Expected: FAILURE — `TenantContext` not found.

- [ ] **Step 3: Create TenantContext**

Create `backend/src/main/java/am/lva/tenancy/TenantContext.java`:

```java
package am.lva.tenancy;

import java.util.UUID;

public final class TenantContext {

    private static final ThreadLocal<UUID> TENANT_ID = new ThreadLocal<>();

    private TenantContext() {}

    public static void set(UUID tenantId) {
        TENANT_ID.set(tenantId);
    }

    public static UUID get() {
        return TENANT_ID.get();
    }

    public static void clear() {
        TENANT_ID.remove();
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd backend && ./mvnw test -Dtest=TenantContextTest -q 2>&1 | tail -5
```

Expected: `Tests run: 3, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 5: Create TenantInterceptor**

Create `backend/src/main/java/am/lva/tenancy/TenantInterceptor.java`:

```java
package am.lva.tenancy;

import am.lva.auth.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class TenantInterceptor implements HandlerInterceptor {

    private final JwtService jwtService;

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) {
        var authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            var token = authHeader.substring(7);
            if (jwtService.isTokenValid(token)) {
                var tenantId = jwtService.extractTenantId(token);
                TenantContext.set(tenantId);
            }
        }
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request,
                                HttpServletResponse response,
                                Object handler, Exception ex) {
        TenantContext.clear();
    }
}
```

- [ ] **Step 6: Create TenantConfig**

Create `backend/src/main/java/am/lva/tenancy/TenantConfig.java`:

```java
package am.lva.tenancy;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@RequiredArgsConstructor
public class TenantConfig implements WebMvcConfigurer {

    private final TenantInterceptor tenantInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(tenantInterceptor).addPathPatterns("/api/**");
    }
}
```

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/am/lva/tenancy/ backend/src/test/java/am/lva/tenancy/
git commit -m "feat: add TenantContext ThreadLocal and request interceptor"
```

---

## Task 5: Car Wash & Bay CRUD

**Files:**
- Create: `backend/src/main/java/am/lva/booking/BayStatus.java`
- Create: `backend/src/main/java/am/lva/booking/VehicleType.java`
- Create: `backend/src/main/java/am/lva/booking/ServiceType.java`
- Create: `backend/src/main/java/am/lva/booking/AvailabilityStatus.java`
- Create: `backend/src/main/java/am/lva/booking/CarWash.java`
- Create: `backend/src/main/java/am/lva/booking/CarWashRepository.java`
- Create: `backend/src/main/java/am/lva/booking/Bay.java`
- Create: `backend/src/main/java/am/lva/booking/BayRepository.java`
- Create: `backend/src/main/java/am/lva/booking/dto/CarWashRequest.java`
- Create: `backend/src/main/java/am/lva/booking/dto/CarWashResponse.java`
- Create: `backend/src/main/java/am/lva/booking/dto/PublicCarWashResponse.java`
- Create: `backend/src/main/java/am/lva/booking/dto/BayRequest.java`
- Create: `backend/src/main/java/am/lva/booking/dto/BayResponse.java`
- Create: `backend/src/main/java/am/lva/booking/CarWashService.java`
- Create: `backend/src/main/java/am/lva/booking/CarWashController.java`
- Create: `backend/src/test/java/am/lva/booking/CarWashControllerTest.java`

- [ ] **Step 1: Write failing tests**

Create `backend/src/test/java/am/lva/booking/CarWashControllerTest.java`:

```java
package am.lva.booking;

import am.lva.BaseIntegrationTest;
import am.lva.auth.AuthService;
import am.lva.auth.UserRepository;
import am.lva.auth.dto.RegisterRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class CarWashControllerTest extends BaseIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired AuthService authService;
    @Autowired UserRepository userRepository;
    @Autowired CarWashRepository carWashRepository;
    @Autowired BayRepository bayRepository;

    private String ownerToken;

    @BeforeEach
    void setup() {
        bayRepository.deleteAll();
        carWashRepository.deleteAll();
        userRepository.deleteAll();
        var response = authService.register(new RegisterRequest("+37477900001", "pass"));
        // Manually set role to OWNER for test
        var user = userRepository.findByPhone("+37477900001").orElseThrow();
        user.setRole(am.lva.auth.UserRole.OWNER);
        userRepository.save(user);
        ownerToken = authService.login(new am.lva.auth.dto.LoginRequest("+37477900001", "pass")).token();
    }

    @Test
    void createAndListCarWash() throws Exception {
        var body = """
                {"name":"AutoSpa","address":"Tigranyan 5","lat":40.18,"lng":44.51}
                """;
        mockMvc.perform(post("/api/owner/car-washes")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.name").value("AutoSpa"));

        mockMvc.perform(get("/api/owner/car-washes")
                        .header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("AutoSpa"));
    }

    @Test
    void createBayForCarWash() throws Exception {
        // Create car wash first
        var washBody = """
                {"name":"AutoSpa","address":"Tigranyan 5","lat":40.18,"lng":44.51}
                """;
        var result = mockMvc.perform(post("/api/owner/car-washes")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(washBody))
                .andExpect(status().isOk())
                .andReturn();
        var carWashId = new com.fasterxml.jackson.databind.ObjectMapper()
                .readTree(result.getResponse().getContentAsString()).get("id").asText();

        // Create bay
        mockMvc.perform(post("/api/owner/car-washes/" + carWashId + "/bays")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Bay 1\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Bay 1"))
                .andExpect(jsonPath("$.status").value("IDLE"));
    }

    @Test
    void publicListingReturnsAvailabilityStatus() throws Exception {
        // Create an owner, car wash and bay using existing ownerToken
        var washBody = """
                {"name":"TestWash","address":"Addr 1","lat":40.19,"lng":44.52}
                """;
        var result = mockMvc.perform(post("/api/owner/car-washes")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON).content(washBody))
                .andReturn();
        var carWashId = new com.fasterxml.jackson.databind.ObjectMapper()
                .readTree(result.getResponse().getContentAsString()).get("id").asText();
        mockMvc.perform(post("/api/owner/car-washes/" + carWashId + "/bays")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"Bay 1\"}"));

        // Register a customer and get public listing
        authService.register(new RegisterRequest("+37477900002", "pass"));
        var customerToken = authService.login(new am.lva.auth.dto.LoginRequest("+37477900002", "pass")).token();

        mockMvc.perform(get("/api/client/car-washes")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].availabilityStatus").value("GREEN"));
    }
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd backend && ./mvnw test -Dtest=CarWashControllerTest -q 2>&1 | tail -5
```

Expected: FAILURE — `CarWashController` not found.

- [ ] **Step 3: Create enums**

Create `backend/src/main/java/am/lva/booking/BayStatus.java`:

```java
package am.lva.booking;
public enum BayStatus { IDLE, OCCUPIED, BLOCKED }
```

Create `backend/src/main/java/am/lva/booking/VehicleType.java`:

```java
package am.lva.booking;
public enum VehicleType { SEDAN, CROSSOVER, SUV, COUPE }
```

Create `backend/src/main/java/am/lva/booking/ServiceType.java`:

```java
package am.lva.booking;
public enum ServiceType { EXTERIOR, INTERIOR, FULL, PREMIUM }
```

Create `backend/src/main/java/am/lva/booking/AvailabilityStatus.java`:

```java
package am.lva.booking;
public enum AvailabilityStatus { GREEN, YELLOW, RED }
```

Create `backend/src/main/java/am/lva/booking/BookingStatus.java`:

```java
package am.lva.booking;
public enum BookingStatus { PENDING, ARRIVED, WASHING, FINISHING, COMPLETED, CANCELLED }
```

- [ ] **Step 4: Create CarWash entity**

Create `backend/src/main/java/am/lva/booking/CarWash.java`:

```java
package am.lva.booking;

import am.lva.auth.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "car_washes")
@Getter @Setter @NoArgsConstructor
public class CarWash {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String address;

    @Column(nullable = false)
    private double lat;

    @Column(nullable = false)
    private double lng;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_user_id", nullable = false)
    private User owner;

    @CreationTimestamp
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
}
```

- [ ] **Step 5: Create CarWashRepository**

Create `backend/src/main/java/am/lva/booking/CarWashRepository.java`:

```java
package am.lva.booking;

import am.lva.auth.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CarWashRepository extends JpaRepository<CarWash, UUID> {
    List<CarWash> findByOwner(User owner);
}
```

- [ ] **Step 6: Create Bay entity**

Create `backend/src/main/java/am/lva/booking/Bay.java`:

```java
package am.lva.booking;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "bays")
@Getter @Setter @NoArgsConstructor
public class Bay {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "car_wash_id", nullable = false)
    private CarWash carWash;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BayStatus status = BayStatus.IDLE;

    @CreationTimestamp
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
}
```

- [ ] **Step 7: Create BayRepository**

Create `backend/src/main/java/am/lva/booking/BayRepository.java`:

```java
package am.lva.booking;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BayRepository extends JpaRepository<Bay, UUID> {
    List<Bay> findByCarWashId(UUID carWashId);
    List<Bay> findByCarWashIdAndStatus(UUID carWashId, BayStatus status);
}
```

- [ ] **Step 8: Create DTOs**

Create `backend/src/main/java/am/lva/booking/dto/CarWashRequest.java`:

```java
package am.lva.booking.dto;

import jakarta.validation.constraints.NotBlank;

public record CarWashRequest(
        @NotBlank String name,
        @NotBlank String address,
        double lat,
        double lng
) {}
```

Create `backend/src/main/java/am/lva/booking/dto/CarWashResponse.java`:

```java
package am.lva.booking.dto;

import am.lva.booking.CarWash;
import java.util.UUID;

public record CarWashResponse(UUID id, String name, String address, double lat, double lng) {
    public static CarWashResponse from(CarWash w) {
        return new CarWashResponse(w.getId(), w.getName(), w.getAddress(), w.getLat(), w.getLng());
    }
}
```

Create `backend/src/main/java/am/lva/booking/dto/PublicCarWashResponse.java`:

```java
package am.lva.booking.dto;

import am.lva.booking.AvailabilityStatus;
import java.util.UUID;

public record PublicCarWashResponse(
        UUID id, String name, double lat, double lng,
        AvailabilityStatus availabilityStatus, int nextSlotMinutes
) {}
```

Create `backend/src/main/java/am/lva/booking/dto/BayRequest.java`:

```java
package am.lva.booking.dto;

import jakarta.validation.constraints.NotBlank;

public record BayRequest(@NotBlank String name) {}
```

Create `backend/src/main/java/am/lva/booking/dto/BayResponse.java`:

```java
package am.lva.booking.dto;

import am.lva.booking.Bay;
import am.lva.booking.BayStatus;
import java.util.UUID;

public record BayResponse(UUID id, String name, BayStatus status) {
    public static BayResponse from(Bay b) {
        return new BayResponse(b.getId(), b.getName(), b.getStatus());
    }
}
```

- [ ] **Step 9: Create CarWashService**

Create `backend/src/main/java/am/lva/booking/CarWashService.java`:

```java
package am.lva.booking;

import am.lva.auth.User;
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
        return carWashRepository.findAll().stream()
                .map(wash -> {
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
                            status, nextSlotMinutes
                    );
                }).toList();
    }
}
```

- [ ] **Step 10: Create CarWashController**

Create `backend/src/main/java/am/lva/booking/CarWashController.java`:

```java
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
public class CarWashController {

    private final CarWashService carWashService;

    @PostMapping("/api/owner/car-washes")
    public CarWashResponse create(@Valid @RequestBody CarWashRequest request,
                                  @AuthenticationPrincipal UUID ownerId) {
        return carWashService.create(request, ownerId);
    }

    @GetMapping("/api/owner/car-washes")
    public List<CarWashResponse> list(@AuthenticationPrincipal UUID ownerId) {
        return carWashService.listByOwner(ownerId);
    }

    @PostMapping("/api/owner/car-washes/{carWashId}/bays")
    public BayResponse createBay(@PathVariable UUID carWashId,
                                 @Valid @RequestBody BayRequest request) {
        return carWashService.createBay(carWashId, request);
    }

    @GetMapping("/api/owner/car-washes/{carWashId}/bays")
    public List<BayResponse> listBays(@PathVariable UUID carWashId) {
        return carWashService.listBays(carWashId);
    }

    @GetMapping("/api/client/car-washes")
    public List<PublicCarWashResponse> publicListing() {
        return carWashService.getPublicListing();
    }
}
```

- [ ] **Step 11: Run tests to verify they pass**

```bash
cd backend && ./mvnw test -Dtest=CarWashControllerTest -q 2>&1 | tail -5
```

Expected: `Tests run: 3, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 12: Commit**

```bash
git add backend/src/
git commit -m "feat: add car wash and bay CRUD with public availability listing"
```

---

## Task 6: Vehicle Garage

**Files:**
- Create: `backend/src/main/java/am/lva/booking/Vehicle.java`
- Create: `backend/src/main/java/am/lva/booking/VehicleRepository.java`
- Create: `backend/src/main/java/am/lva/booking/dto/VehicleRequest.java`
- Create: `backend/src/main/java/am/lva/booking/dto/VehicleResponse.java`
- Create: `backend/src/main/java/am/lva/booking/VehicleService.java`
- Create: `backend/src/main/java/am/lva/booking/VehicleController.java`
- Create: `backend/src/test/java/am/lva/booking/VehicleControllerTest.java`

- [ ] **Step 1: Write failing tests**

Create `backend/src/test/java/am/lva/booking/VehicleControllerTest.java`:

```java
package am.lva.booking;

import am.lva.BaseIntegrationTest;
import am.lva.auth.AuthService;
import am.lva.auth.UserRepository;
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
        customerToken = authService.login(new am.lva.auth.dto.LoginRequest("+37477800001", "pass")).token();
    }

    @Test
    void addAndListVehicle() throws Exception {
        var body = """
                {"plate":"AM1234AB","type":"SEDAN","nickname":"My Car"}
                """;
        mockMvc.perform(post("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.plate").value("AM1234AB"))
                .andExpect(jsonPath("$.type").value("SEDAN"));

        mockMvc.perform(get("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].plate").value("AM1234AB"));
    }
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd backend && ./mvnw test -Dtest=VehicleControllerTest -q 2>&1 | tail -5
```

Expected: FAILURE.

- [ ] **Step 3: Create Vehicle entity**

Create `backend/src/main/java/am/lva/booking/Vehicle.java`:

```java
package am.lva.booking;

import am.lva.auth.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "vehicles")
@Getter @Setter @NoArgsConstructor
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String plate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VehicleType type;

    private String nickname;

    @CreationTimestamp
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
}
```

- [ ] **Step 4: Create VehicleRepository**

Create `backend/src/main/java/am/lva/booking/VehicleRepository.java`:

```java
package am.lva.booking;

import am.lva.auth.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface VehicleRepository extends JpaRepository<Vehicle, UUID> {
    List<Vehicle> findByUser(User user);
}
```

- [ ] **Step 5: Create DTOs**

Create `backend/src/main/java/am/lva/booking/dto/VehicleRequest.java`:

```java
package am.lva.booking.dto;

import am.lva.booking.VehicleType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record VehicleRequest(
        @NotBlank String plate,
        @NotNull VehicleType type,
        String nickname
) {}
```

Create `backend/src/main/java/am/lva/booking/dto/VehicleResponse.java`:

```java
package am.lva.booking.dto;

import am.lva.booking.Vehicle;
import am.lva.booking.VehicleType;
import java.util.UUID;

public record VehicleResponse(UUID id, String plate, VehicleType type, String nickname) {
    public static VehicleResponse from(Vehicle v) {
        return new VehicleResponse(v.getId(), v.getPlate(), v.getType(), v.getNickname());
    }
}
```

- [ ] **Step 6: Create VehicleService**

Create `backend/src/main/java/am/lva/booking/VehicleService.java`:

```java
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
```

- [ ] **Step 7: Create VehicleController**

Create `backend/src/main/java/am/lva/booking/VehicleController.java`:

```java
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
```

- [ ] **Step 8: Run tests**

```bash
cd backend && ./mvnw test -Dtest=VehicleControllerTest -q 2>&1 | tail -5
```

Expected: `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 9: Commit**

```bash
git add backend/src/
git commit -m "feat: add vehicle garage endpoints (add and list vehicles)"
```

---

## Task 7: Booking Engine (Slot Availability + Create Booking)

**Files:**
- Create: `backend/src/main/java/am/lva/booking/Price.java`
- Create: `backend/src/main/java/am/lva/booking/PriceRepository.java`
- Create: `backend/src/main/java/am/lva/booking/Booking.java`
- Create: `backend/src/main/java/am/lva/booking/BookingRepository.java`
- Create: `backend/src/main/java/am/lva/booking/WalkIn.java`
- Create: `backend/src/main/java/am/lva/booking/WalkInRepository.java`
- Create: `backend/src/main/java/am/lva/booking/dto/SlotResponse.java`
- Create: `backend/src/main/java/am/lva/booking/dto/BookingRequest.java`
- Create: `backend/src/main/java/am/lva/booking/dto/BookingResponse.java`
- Create: `backend/src/main/java/am/lva/booking/dto/WalkInRequest.java`
- Create: `backend/src/main/java/am/lva/booking/dto/StatusUpdateRequest.java`
- Create: `backend/src/main/java/am/lva/booking/SlotService.java`
- Create: `backend/src/main/java/am/lva/booking/BookingService.java`
- Create: `backend/src/main/java/am/lva/booking/BookingController.java`
- Create: `backend/src/test/java/am/lva/booking/SlotServiceTest.java`
- Create: `backend/src/test/java/am/lva/booking/BookingControllerTest.java`

- [ ] **Step 1: Write SlotService unit test**

Create `backend/src/test/java/am/lva/booking/SlotServiceTest.java`:

```java
package am.lva.booking;

import am.lva.BaseIntegrationTest;
import am.lva.auth.AuthService;
import am.lva.auth.UserRepository;
import am.lva.auth.dto.RegisterRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.OffsetDateTime;

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

    private CarWash carWash;
    private Bay bay;

    @BeforeEach
    void setup() {
        walkInRepository.deleteAll();
        bookingRepository.deleteAll();
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
    }

    @Test
    void noSlotsWhenBayOccupied() {
        bay.setStatus(BayStatus.OCCUPIED);
        bayRepository.save(bay);

        var slots = slotService.getAvailableSlots(
                carWash.getId(), VehicleType.SEDAN, ServiceType.EXTERIOR);
        assertThat(slots).isEmpty();
    }
}
```

- [ ] **Step 2: Write BookingController integration test**

Create `backend/src/test/java/am/lva/booking/BookingControllerTest.java`:

```java
package am.lva.booking;

import am.lva.BaseIntegrationTest;
import am.lva.auth.AuthService;
import am.lva.auth.UserRepository;
import am.lva.auth.dto.RegisterRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class BookingControllerTest extends BaseIntegrationTest {

    @Autowired MockMvc mockMvc;
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
        var moderator = userRepository.findByPhone("+37477600002").orElseThrow();
        moderator.setRole(am.lva.auth.UserRole.MODERATOR);
        userRepository.save(moderator);
        moderatorToken = authService.login(new am.lva.auth.dto.LoginRequest("+37477600002", "pass")).token();

        authService.register(new RegisterRequest("+37477600003", "pass"));
        customerToken = authService.login(new am.lva.auth.dto.LoginRequest("+37477600003", "pass")).token();

        carWash = new CarWash();
        carWash.setName("Test Wash");
        carWash.setAddress("Addr");
        carWash.setLat(40.18); carWash.setLng(44.51);
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
        // Add vehicle
        var vehicleResult = mockMvc.perform(post("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"plate\":\"AM1234AB\",\"type\":\"SEDAN\"}"))
                .andReturn();
        var vehicleId = new com.fasterxml.jackson.databind.ObjectMapper()
                .readTree(vehicleResult.getResponse().getContentAsString()).get("id").asText();

        var slotStart = OffsetDateTime.now().plusMinutes(10)
                .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        var body = String.format(
                "{\"carWashId\":\"%s\",\"vehicleId\":\"%s\",\"serviceType\":\"EXTERIOR\",\"slotStartsAt\":\"%s\"}",
                carWash.getId(), vehicleId, slotStart
        );

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
        // Create a booking first
        var vehicleResult = mockMvc.perform(post("/api/client/vehicles")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"plate\":\"AM5678CD\",\"type\":\"SEDAN\"}"))
                .andReturn();
        var vehicleId = new com.fasterxml.jackson.databind.ObjectMapper()
                .readTree(vehicleResult.getResponse().getContentAsString()).get("id").asText();

        var slotStart = OffsetDateTime.now().plusMinutes(5)
                .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        var createBody = String.format(
                "{\"carWashId\":\"%s\",\"vehicleId\":\"%s\",\"serviceType\":\"EXTERIOR\",\"slotStartsAt\":\"%s\"}",
                carWash.getId(), vehicleId, slotStart
        );
        var bookingResult = mockMvc.perform(post("/api/client/bookings")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andReturn();
        var bookingId = new com.fasterxml.jackson.databind.ObjectMapper()
                .readTree(bookingResult.getResponse().getContentAsString()).get("id").asText();

        // Moderator updates status
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

        // Bay should now be OCCUPIED
        var updatedBay = bayRepository.findById(bay.getId()).orElseThrow();
        org.assertj.core.api.Assertions.assertThat(updatedBay.getStatus())
                .isEqualTo(BayStatus.OCCUPIED);
    }
}
```

- [ ] **Step 3: Run to verify failure**

```bash
cd backend && ./mvnw test -Dtest="SlotServiceTest,BookingControllerTest" -q 2>&1 | tail -5
```

Expected: FAILURE.

- [ ] **Step 4: Create Price entity**

Create `backend/src/main/java/am/lva/booking/Price.java`:

```java
package am.lva.booking;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "prices")
@Getter @Setter @NoArgsConstructor
public class Price {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "car_wash_id", nullable = false)
    private CarWash carWash;

    @Enumerated(EnumType.STRING)
    @Column(name = "vehicle_type", nullable = false)
    private VehicleType vehicleType;

    @Enumerated(EnumType.STRING)
    @Column(name = "service_type", nullable = false)
    private ServiceType serviceType;

    @Column(name = "duration_minutes", nullable = false)
    private int durationMinutes;

    @Column(name = "amount_amd", nullable = false)
    private int amountAmd;
}
```

- [ ] **Step 5: Create PriceRepository**

Create `backend/src/main/java/am/lva/booking/PriceRepository.java`:

```java
package am.lva.booking;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PriceRepository extends JpaRepository<Price, UUID> {
    Optional<Price> findByCarWashIdAndVehicleTypeAndServiceType(
            UUID carWashId, VehicleType vehicleType, ServiceType serviceType);
}
```

- [ ] **Step 6: Create Booking entity**

Create `backend/src/main/java/am/lva/booking/Booking.java`:

```java
package am.lva.booking;

import am.lva.auth.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "bookings")
@Getter @Setter @NoArgsConstructor
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bay_id", nullable = false)
    private Bay bay;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id", nullable = false)
    private Vehicle vehicle;

    @Enumerated(EnumType.STRING)
    @Column(name = "service_type", nullable = false)
    private ServiceType serviceType;

    @Column(name = "starts_at", nullable = false)
    private OffsetDateTime startsAt;

    @Column(name = "ends_at", nullable = false)
    private OffsetDateTime endsAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BookingStatus status = BookingStatus.PENDING;

    @CreationTimestamp
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
}
```

- [ ] **Step 7: Create BookingRepository**

Create `backend/src/main/java/am/lva/booking/BookingRepository.java`:

```java
package am.lva.booking;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface BookingRepository extends JpaRepository<Booking, UUID> {

    @Query("""
        SELECT b FROM Booking b
        WHERE b.bay.id = :bayId
        AND b.status NOT IN (am.lva.booking.BookingStatus.COMPLETED, am.lva.booking.BookingStatus.CANCELLED)
        AND b.startsAt < :endsAt AND b.endsAt > :startsAt
        """)
    List<Booking> findOverlapping(@Param("bayId") UUID bayId,
                                  @Param("startsAt") OffsetDateTime startsAt,
                                  @Param("endsAt") OffsetDateTime endsAt);
}
```

- [ ] **Step 8: Create WalkIn entity and repository**

Create `backend/src/main/java/am/lva/booking/WalkIn.java`:

```java
package am.lva.booking;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "walk_ins")
@Getter @Setter @NoArgsConstructor
public class WalkIn {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bay_id", nullable = false)
    private Bay bay;

    @Column(name = "starts_at", nullable = false)
    private OffsetDateTime startsAt;

    @Column(name = "ends_at", nullable = false)
    private OffsetDateTime endsAt;

    @CreationTimestamp
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
}
```

Create `backend/src/main/java/am/lva/booking/WalkInRepository.java`:

```java
package am.lva.booking;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface WalkInRepository extends JpaRepository<WalkIn, UUID> {}
```

- [ ] **Step 9: Create DTOs**

Create `backend/src/main/java/am/lva/booking/dto/SlotResponse.java`:

```java
package am.lva.booking.dto;

import java.time.OffsetDateTime;

public record SlotResponse(OffsetDateTime startsAt, int durationMinutes, int amountAmd) {}
```

Create `backend/src/main/java/am/lva/booking/dto/BookingRequest.java`:

```java
package am.lva.booking.dto;

import jakarta.validation.constraints.NotNull;
import java.time.OffsetDateTime;
import java.util.UUID;

public record BookingRequest(
        @NotNull UUID carWashId,
        @NotNull UUID vehicleId,
        @NotNull String serviceType,
        @NotNull OffsetDateTime slotStartsAt
) {}
```

Create `backend/src/main/java/am/lva/booking/dto/BookingResponse.java`:

```java
package am.lva.booking.dto;

import am.lva.booking.Booking;
import am.lva.booking.BookingStatus;
import java.time.OffsetDateTime;
import java.util.UUID;

public record BookingResponse(
        UUID id, UUID bayId, BookingStatus status,
        OffsetDateTime startsAt, OffsetDateTime endsAt
) {
    public static BookingResponse from(Booking b) {
        return new BookingResponse(b.getId(), b.getBay().getId(),
                b.getStatus(), b.getStartsAt(), b.getEndsAt());
    }
}
```

Create `backend/src/main/java/am/lva/booking/dto/WalkInRequest.java`:

```java
package am.lva.booking.dto;

import jakarta.validation.constraints.Min;

public record WalkInRequest(@Min(1) int estimatedDurationMinutes) {}
```

Create `backend/src/main/java/am/lva/booking/dto/StatusUpdateRequest.java`:

```java
package am.lva.booking.dto;

import am.lva.booking.BookingStatus;
import jakarta.validation.constraints.NotNull;

public record StatusUpdateRequest(@NotNull BookingStatus status) {}
```

- [ ] **Step 10: Create SlotService**

Create `backend/src/main/java/am/lva/booking/SlotService.java`:

```java
package am.lva.booking;

import am.lva.booking.dto.SlotResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SlotService {

    private final BayRepository bayRepository;
    private final PriceRepository priceRepository;
    private final BookingRepository bookingRepository;

    public List<SlotResponse> getAvailableSlots(UUID carWashId,
                                                 VehicleType vehicleType,
                                                 ServiceType serviceType) {
        var price = priceRepository.findByCarWashIdAndVehicleTypeAndServiceType(
                carWashId, vehicleType, serviceType).orElse(null);
        if (price == null) return List.of();

        var idleBays = bayRepository.findByCarWashIdAndStatus(carWashId, BayStatus.IDLE);
        if (idleBays.isEmpty()) return List.of();

        var slots = new ArrayList<SlotResponse>();
        var now = OffsetDateTime.now();
        for (int i = 0; i < 8; i++) {
            var start = now.plusMinutes((long) i * price.getDurationMinutes());
            var end = start.plusMinutes(price.getDurationMinutes());
            var hasAvailableBay = idleBays.stream().anyMatch(bay ->
                    bookingRepository.findOverlapping(bay.getId(), start, end).isEmpty());
            if (hasAvailableBay) {
                slots.add(new SlotResponse(start, price.getDurationMinutes(), price.getAmountAmd()));
            }
        }
        return slots;
    }
}
```

- [ ] **Step 11: Create BookingService**

Create `backend/src/main/java/am/lva/booking/BookingService.java`:

```java
package am.lva.booking;

import am.lva.auth.UserRepository;
import am.lva.booking.dto.BookingRequest;
import am.lva.booking.dto.BookingResponse;
import am.lva.booking.dto.StatusUpdateRequest;
import am.lva.booking.dto.WalkInRequest;
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
                .orElseThrow(() -> new IllegalStateException("No available bay"));

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

        notificationService.broadcastBayStatus(bay.getCarWash().getId(), bay.getId(), bay.getStatus());
        return BookingResponse.from(booking);
    }

    @Transactional
    public BookingResponse updateStatus(UUID bookingId, StatusUpdateRequest request) {
        var booking = bookingRepository.findById(bookingId).orElseThrow();
        booking.setStatus(request.status());
        if (request.status() == BookingStatus.COMPLETED || request.status() == BookingStatus.CANCELLED) {
            booking.getBay().setStatus(BayStatus.IDLE);
            bayRepository.save(booking.getBay());
        } else {
            booking.getBay().setStatus(BayStatus.OCCUPIED);
            bayRepository.save(booking.getBay());
        }
        bookingRepository.save(booking);
        notificationService.broadcastBayStatus(
                booking.getBay().getCarWash().getId(),
                booking.getBay().getId(),
                booking.getBay().getStatus());
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
        notificationService.broadcastBayStatus(bay.getCarWash().getId(), bay.getId(), bay.getStatus());
    }
}
```

- [ ] **Step 12: Create BookingController**

Create `backend/src/main/java/am/lva/booking/BookingController.java`:

```java
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
```

- [ ] **Step 13: Run tests (after Task 8 adds NotificationService stub)**

Skip running until NotificationService exists (next task). Move forward.

- [ ] **Step 14: Commit entities and DTOs**

```bash
git add backend/src/
git commit -m "feat: add booking engine entities, slot service, booking/walk-in endpoints"
```

---

## Task 8: WebSocket STOMP Infrastructure + NotificationService

**Files:**
- Create: `backend/src/main/java/am/lva/notifications/WebSocketConfig.java`
- Create: `backend/src/main/java/am/lva/notifications/BayStatusMessage.java`
- Create: `backend/src/main/java/am/lva/notifications/NotificationService.java`
- Create: `backend/src/test/java/am/lva/notifications/NotificationServiceTest.java`

- [ ] **Step 1: Write failing test**

Create `backend/src/test/java/am/lva/notifications/NotificationServiceTest.java`:

```java
package am.lva.notifications;

import am.lva.BaseIntegrationTest;
import am.lva.booking.BayStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.mockito.Mockito;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;

class NotificationServiceTest extends BaseIntegrationTest {

    @Autowired
    NotificationService notificationService;

    @Test
    void broadcastDoesNotThrow() {
        // NotificationService must not throw even with a real broker
        var carWashId = UUID.randomUUID();
        var bayId = UUID.randomUUID();
        org.assertj.core.api.Assertions.assertThatCode(() ->
                notificationService.broadcastBayStatus(carWashId, bayId, BayStatus.IDLE)
        ).doesNotThrowAnyException();
    }
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd backend && ./mvnw test -Dtest=NotificationServiceTest -q 2>&1 | tail -5
```

Expected: FAILURE — `NotificationService` not found.

- [ ] **Step 3: Create WebSocketConfig**

Create `backend/src/main/java/am/lva/notifications/WebSocketConfig.java`:

```java
package am.lva.notifications;

import am.lva.auth.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.List;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtService jwtService;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").setAllowedOriginPatterns("*").withSockJS();
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                var accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
                if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
                    var authHeader = accessor.getFirstNativeHeader("Authorization");
                    if (authHeader != null && authHeader.startsWith("Bearer ")) {
                        var token = authHeader.substring(7);
                        if (jwtService.isTokenValid(token)) {
                            var userId = jwtService.extractUserId(token);
                            var role = jwtService.extractRole(token);
                            accessor.setUser(new UsernamePasswordAuthenticationToken(
                                    userId, null,
                                    List.of(new SimpleGrantedAuthority("ROLE_" + role.name()))
                            ));
                        }
                    }
                }
                return message;
            }
        });
    }
}
```

- [ ] **Step 4: Create BayStatusMessage**

Create `backend/src/main/java/am/lva/notifications/BayStatusMessage.java`:

```java
package am.lva.notifications;

import am.lva.booking.BayStatus;
import java.util.UUID;

public record BayStatusMessage(UUID bayId, BayStatus status) {}
```

- [ ] **Step 5: Create NotificationService**

Create `backend/src/main/java/am/lva/notifications/NotificationService.java`:

```java
package am.lva.notifications;

import am.lva.booking.BayStatus;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final SimpMessagingTemplate messagingTemplate;

    public void broadcastBayStatus(UUID carWashId, UUID bayId, BayStatus status) {
        var destination = "/topic/carwash/" + carWashId + "/bays";
        var message = new BayStatusMessage(bayId, status);
        messagingTemplate.convertAndSend(destination, message);
        log.debug("Broadcast bay status: {} -> {}", bayId, status);
    }
}
```

- [ ] **Step 6: Run all tests**

```bash
cd backend && ./mvnw test -q 2>&1 | tail -10
```

Expected: All tests pass. Look for: `Tests run: N, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 7: Commit**

```bash
git add backend/src/
git commit -m "feat: add WebSocket STOMP config and NotificationService for bay status broadcast"
```

---

## Task 9: Full Test Suite Run + Verify

- [ ] **Step 1: Run all tests**

```bash
cd backend && ./mvnw test 2>&1 | tail -20
```

Expected: All test classes pass — `FlywayMigrationTest`, `JwtServiceTest`, `AuthControllerTest`, `TenantContextTest`, `CarWashControllerTest`, `VehicleControllerTest`, `SlotServiceTest`, `BookingControllerTest`, `NotificationServiceTest`.

- [ ] **Step 2: Verify application context loads**

```bash
cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=test &
sleep 15
curl -s http://localhost:8080/v3/api-docs | python3 -c "import sys,json; d=json.load(sys.stdin); print('Paths:', list(d['paths'].keys())[:5])"
kill %1
```

Expected: JSON response listing API paths including `/api/auth/login`, `/api/client/car-washes`, etc.

- [ ] **Step 3: Final commit**

```bash
git add backend/
git commit -m "feat: complete backend Phase 1 — auth, tenancy, car wash/bay CRUD, booking engine, WebSocket"
```

---

## Self-Review Checklist

**Spec coverage:**
- ✅ Epic 1: Flyway migration with all 10 tables (Task 1)
- ✅ Epic 2: Register, login, role-based route protection (Tasks 2, 3)
- ✅ Epic 3: TenantContext ThreadLocal + request interceptor (Task 4)
- ✅ Epic 4: Car wash CRUD, bay CRUD, public listing with GREEN/YELLOW/RED (Task 5)
- ✅ Epic 5: Slot availability, create booking, walk-in override, status transitions (Tasks 7, 8)
- ✅ Epic 6: Vehicle add + list (Task 6)
- ✅ Epic 9: STOMP WebSocket config + NotificationService broadcast (Task 8)
- ⏭ Epics 7, 8, 10, 11: Deferred to Phase 2 plan

**Type consistency:** All DTOs are Java records. `BookingService` references `NotificationService` — NotificationService is created in Task 8, BookingService in Task 7. Plan order ensures compilation succeeds after Task 8 completes. Run full test suite in Task 9 validates end-to-end.
