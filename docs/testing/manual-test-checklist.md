# Lva Manual Testing Checklist

Run these tests after starting the full stack. Check each item when verified.

## Prerequisites

- [ ] PostgreSQL running: `docker compose up postgres -d`
- [ ] Backend running: `cd backend && mvn spring-boot:run`
- [ ] Admin web running: `cd admin-web && npm run dev` (use Node 20: `nvm use 20`)
- [ ] Swagger UI accessible: http://localhost:8080/swagger-ui.html
- [ ] Admin web accessible: http://localhost:3000

---

## 1. Auth Flows

### 1.1 Register a customer
- [ ] POST `/api/auth/register` with `{"phone":"+37477000001","password":"pass123"}`
- [ ] Response: `200 OK` with `token` and `role: "CUSTOMER"`

### 1.2 Register and promote an owner
- [ ] POST `/api/auth/register` with `{"phone":"+37477000002","password":"pass123"}`
- [ ] Update role in DB (via Adminer at http://localhost:8080/swagger-ui.html or psql):
  ```sql
  UPDATE users SET role='OWNER' WHERE phone='+37477000002';
  ```
- [ ] POST `/api/auth/login` → save the owner token

### 1.3 Register a moderator
- [ ] POST `/api/auth/register` with `{"phone":"+37477000003","password":"pass123"}`
- [ ] `UPDATE users SET role='MODERATOR' WHERE phone='+37477000003';`

### 1.4 Duplicate phone returns 409
- [ ] POST `/api/auth/register` twice with same phone → second returns `409 Conflict`

### 1.5 Wrong password returns 401
- [ ] POST `/api/auth/login` with wrong password → `401 Unauthorized`

---

## 2. Car Wash & Bay Setup

Using the owner token from 1.2:

### 2.1 Create a car wash
- [ ] POST `/api/owner/car-washes`
  ```json
  {"name":"AutoSpa Kentron","address":"Tigranyan St 5","lat":40.1872,"lng":44.5152}
  ```
- [ ] Response: `200 OK` with `id` → save as `CAR_WASH_ID`

### 2.2 List car washes
- [ ] GET `/api/owner/car-washes` → shows the created car wash

### 2.3 Add bays
- [ ] POST `/api/owner/car-washes/{CAR_WASH_ID}/bays` with `{"name":"Bay 1"}` → save `BAY_1_ID`
- [ ] POST `/api/owner/car-washes/{CAR_WASH_ID}/bays` with `{"name":"Bay 2"}` → save `BAY_2_ID`
- [ ] Both return `status: "IDLE"`

---

## 3. Pricing Setup

### 3.1 Set prices
- [ ] PUT `/api/owner/car-washes/{CAR_WASH_ID}/prices`
  ```json
  {
    "prices": [
      {"vehicleType":"SEDAN","serviceType":"EXTERIOR","durationMinutes":25,"amountAmd":3500},
      {"vehicleType":"SEDAN","serviceType":"FULL","durationMinutes":45,"amountAmd":6500},
      {"vehicleType":"SUV","serviceType":"EXTERIOR","durationMinutes":35,"amountAmd":5000}
    ]
  }
  ```
- [ ] Response: array of 3 prices

### 3.2 List prices
- [ ] GET `/api/owner/car-washes/{CAR_WASH_ID}/prices` → 3 prices returned

---

## 4. Customer Booking Flow

Using customer token from 1.1:

### 4.1 Public car wash listing
- [ ] GET `/api/client/car-washes` → includes `AutoSpa Kentron` with `availabilityStatus: "GREEN"`

### 4.2 Available slots
- [ ] GET `/api/client/car-washes/{CAR_WASH_ID}/slots?vehicleType=SEDAN&serviceType=EXTERIOR`
- [ ] Response: array of slots with `durationMinutes: 25` and `amountAmd: 3500`

### 4.3 Add a vehicle
- [ ] POST `/api/client/vehicles` with `{"plate":"AM1234AB","type":"SEDAN","nickname":"My Car"}`
- [ ] Response: `200 OK` with `id` → save as `VEHICLE_ID`

### 4.4 Create a booking
- [ ] POST `/api/client/bookings`
  ```json
  {
    "carWashId": "{CAR_WASH_ID}",
    "vehicleId": "{VEHICLE_ID}",
    "serviceType": "EXTERIOR",
    "slotStartsAt": "<ISO 8601 timestamp, now + 10 minutes>"
  }
  ```
- [ ] Response: `status: "PENDING"` → save `BOOKING_ID`

### 4.5 Vehicle ownership protection
- [ ] Register a second customer (phone `+37477000004`)
- [ ] Try booking with second customer's token using first customer's `VEHICLE_ID`
- [ ] Response: `400 Bad Request`

---

## 5. Moderator Bay Management

Using moderator token from 1.3:

### 5.1 Status: ARRIVED
- [ ] PUT `/api/moderator/bookings/{BOOKING_ID}/status` → `{"status":"ARRIVED"}`
- [ ] Response: `status: "ARRIVED"`

### 5.2 Status: WASHING
- [ ] PUT `/api/moderator/bookings/{BOOKING_ID}/status` → `{"status":"WASHING"}`
- [ ] Response: `status: "WASHING"`

### 5.3 Status: COMPLETED
- [ ] PUT `/api/moderator/bookings/{BOOKING_ID}/status` → `{"status":"COMPLETED"}`
- [ ] GET `/api/owner/car-washes/{CAR_WASH_ID}/bays` → the bay is now `IDLE` again

### 5.4 Walk-in override
- [ ] POST `/api/moderator/bays/{BAY_1_ID}/walk-ins` → `{"estimatedDurationMinutes":30}`
- [ ] Response: `200 OK`
- [ ] GET `/api/owner/car-washes/{CAR_WASH_ID}/bays` → Bay 1 is `OCCUPIED`

---

## 6. Admin Web Integration

### 6.1 Login as owner
- [ ] Open http://localhost:3000 → redirected to `/login`
- [ ] Enter owner phone (`+37477000002`) and password
- [ ] Redirected to `/owner` dashboard

### 6.2 Owner dashboard shows real data
- [ ] Car wash name and address shown in header
- [ ] Bay 1 card shows `OCCUPIED` (from walk-in in step 5.4)
- [ ] Bay 2 card shows `IDLE`
- [ ] Status colors correct: green border = IDLE, blue border = OCCUPIED

### 6.3 Live bay status update (WebSocket)
- [ ] Open DevTools → Network → WS tab
- [ ] Confirm WebSocket connection to `ws://localhost:8080/ws` established
- [ ] In Swagger UI, call PUT `/api/moderator/bookings/{BOOKING_ID}/status` with `{"status":"COMPLETED"}` using moderator token
- [ ] Bay card in the dashboard updates within ~2 seconds WITHOUT page refresh

### 6.4 Pricing page loads saved prices
- [ ] Navigate to http://localhost:3000/owner/pricing
- [ ] Sedan Exterior shows 3,500 ֏ / 25 min
- [ ] Sedan Full shows 6,500 ֏ / 45 min
- [ ] SUV Exterior shows 5,000 ֏ / 35 min

### 6.5 Save updated price
- [ ] Change Sedan Exterior price to 4,000 ֏
- [ ] Click "Save Prices" → "✓ Prices saved" appears
- [ ] Refresh page → 4,000 ֏ persists
- [ ] GET `/api/owner/car-washes/{CAR_WASH_ID}/prices` → confirms updated price

### 6.6 Sign out
- [ ] Click "↩ Sign out" in sidebar
- [ ] Redirected to `/login`
- [ ] Navigate to http://localhost:3000/owner → redirected to `/login` (middleware working)

---

## 7. Backend Tests

- [ ] `cd backend && mvn test` → all 24 tests pass

---

## Sign-Off

| Area | Result | Notes |
|---|---|---|
| Auth flows | | |
| Car wash & bay setup | | |
| Pricing API | | |
| Customer booking | | |
| Moderator status updates | | |
| Admin web login | | |
| Admin web live bay updates | | |
| Admin web pricing management | | |
| Backend test suite | | |
