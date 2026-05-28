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
