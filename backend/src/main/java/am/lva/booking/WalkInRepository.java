package am.lva.booking;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface WalkInRepository extends JpaRepository<WalkIn, UUID> {}
