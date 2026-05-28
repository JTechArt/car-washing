package am.lva.notifications;

import am.lva.booking.BayStatus;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@Slf4j
public class NotificationService {

    public void broadcastBayStatus(UUID carWashId, UUID bayId, BayStatus status) {
        log.debug("Bay status update: carWash={} bay={} status={}", carWashId, bayId, status);
    }
}
