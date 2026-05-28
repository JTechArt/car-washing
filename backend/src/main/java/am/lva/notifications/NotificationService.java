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
        messagingTemplate.convertAndSend(destination, new BayStatusMessage(bayId, status));
        log.debug("Broadcast bay status: carWash={} bay={} -> {}", carWashId, bayId, status);
    }
}
