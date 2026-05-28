package am.lva.booking;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface BayRepository extends JpaRepository<Bay, UUID> {
    List<Bay> findByCarWashId(UUID carWashId);
    List<Bay> findByCarWashIdAndStatus(UUID carWashId, BayStatus status);
}
