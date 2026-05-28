package am.lva;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import javax.sql.DataSource;

import static org.assertj.core.api.Assertions.assertThat;

class FlywayMigrationTest extends BaseIntegrationTest {

    @Autowired
    DataSource dataSource;

    @Test
    void allTablesCreated() throws Exception {
        try (var conn = dataSource.getConnection()) {
            var tables = new String[]{"tenants","users","car_washes","bays",
                    "vehicles","bookings","walk_ins","prices","subscriptions","corporate_accounts"};
            for (String table : tables) {
                var rs = conn.getMetaData().getTables(null, null, table, null);
                assertThat(rs.next()).as("Table %s must exist", table).isTrue();
            }
        }
    }
}
