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
    void invalidTokenReturnsFalse() {
        assertThat(jwtService.isTokenValid("bad.token.here")).isFalse();
    }
}
