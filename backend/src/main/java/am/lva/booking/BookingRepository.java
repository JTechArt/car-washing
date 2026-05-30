package am.lva.booking;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface BookingRepository extends JpaRepository<Booking, UUID> {

    @Query("""
        SELECT b FROM Booking b
        WHERE b.bay.id = :bayId
        AND b.status NOT IN ('COMPLETED', 'CANCELLED')
        AND b.startsAt < :endsAt AND b.endsAt > :startsAt
        """)
    List<Booking> findOverlapping(@Param("bayId") UUID bayId,
                                  @Param("startsAt") OffsetDateTime startsAt,
                                  @Param("endsAt") OffsetDateTime endsAt);

    @EntityGraph(attributePaths = {"bay", "bay.carWash", "vehicle"})
    List<Booking> findByUserIdOrderByStartsAtDesc(UUID userId);

    @Query("""
        SELECT b FROM Booking b
        WHERE b.bay.id = :bayId
        AND b.status NOT IN ('COMPLETED', 'CANCELLED')
        ORDER BY b.startsAt DESC
        """)
    List<Booking> findActiveByBayId(@Param("bayId") UUID bayId);
}
