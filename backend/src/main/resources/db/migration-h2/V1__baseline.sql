-- H2-compatible version of V1__baseline.sql used for tests.
-- Production uses db/migration/V1__baseline.sql (PostgreSQL syntax).
-- Differences: RANDOM_UUID() instead of gen_random_uuid(), TIMESTAMP instead of TIMESTAMPTZ,
-- DOUBLE instead of DOUBLE PRECISION, DEFAULT before PRIMARY KEY.

CREATE TABLE tenants (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  logo_url TEXT,
  theme_color VARCHAR(7),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id),
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255),
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('CUSTOMER','MODERATOR','OWNER','SUPER_ADMIN')),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE car_washes (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id),
  name VARCHAR(255) NOT NULL,
  address TEXT NOT NULL,
  lat DOUBLE NOT NULL,
  lng DOUBLE NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE bays (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id),
  car_wash_id UUID NOT NULL REFERENCES car_washes(id),
  name VARCHAR(100) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'IDLE' CHECK (status IN ('IDLE','OCCUPIED','BLOCKED')),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE vehicles (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  plate VARCHAR(20) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('SEDAN','CROSSOVER','SUV','COUPE')),
  nickname VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE prices (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id),
  car_wash_id UUID NOT NULL REFERENCES car_washes(id),
  vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('SEDAN','CROSSOVER','SUV','COUPE')),
  service_type VARCHAR(50) NOT NULL,
  duration_minutes INT NOT NULL,
  amount_amd INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (car_wash_id, vehicle_type, service_type)
);

CREATE TABLE bookings (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id),
  bay_id UUID NOT NULL REFERENCES bays(id),
  user_id UUID NOT NULL REFERENCES users(id),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  service_type VARCHAR(50) NOT NULL,
  starts_at TIMESTAMP NOT NULL,
  ends_at TIMESTAMP NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ARRIVED','WASHING','FINISHING','COMPLETED','CANCELLED')),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID','PAID','REFUNDED')),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE walk_ins (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id),
  bay_id UUID NOT NULL REFERENCES bays(id),
  starts_at TIMESTAMP NOT NULL,
  ends_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE subscriptions (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  plan_id VARCHAR(50) NOT NULL,
  valid_from TIMESTAMP NOT NULL,
  valid_to TIMESTAMP NOT NULL,
  washes_remaining INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE corporate_accounts (
  id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id),
  company_name VARCHAR(255) NOT NULL,
  billing_cycle VARCHAR(20) NOT NULL CHECK (billing_cycle IN ('MONTHLY','QUARTERLY')),
  balance_amd INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_bookings_bay_time ON bookings(bay_id, starts_at, ends_at);
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bays_car_wash ON bays(car_wash_id);
CREATE INDEX idx_car_washes_location ON car_washes(lat, lng);
