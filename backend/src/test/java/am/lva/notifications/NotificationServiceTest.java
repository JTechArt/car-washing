package am.lva.notifications;

import am.lva.BaseIntegrationTest;
import am.lva.booking.BayStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;

class NotificationServiceTest extends BaseIntegrationTest {

    @Autowired
    NotificationService notificationService;

    @Test
    void broadcastDoesNotThrow() {
        assertThatCode(() ->
                notificationService.broadcastBayStatus(
                        UUID.randomUUID(), UUID.randomUUID(), BayStatus.IDLE)
        ).doesNotThrowAnyException();
    }

    @Test
    void broadcastWithOccupiedStatus() {
        assertThatCode(() ->
                notificationService.broadcastBayStatus(
                        UUID.randomUUID(), UUID.randomUUID(), BayStatus.OCCUPIED)
        ).doesNotThrowAnyException();
    }
}
