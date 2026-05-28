package am.lva.booking;

import am.lva.auth.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface CarWashRepository extends JpaRepository<CarWash, UUID> {
    List<CarWash> findByOwner(User owner);
}
