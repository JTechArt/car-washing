# Product Requirement Document (PRD)

## Project Title: Lva (Լվա) — Next-Gen Auto Care Ecosystem
**Document Version:** 1.0  
[cite_start]**Target Market:** Armenia (Starting with Yerevan) [cite: 114]

---

## 1. Executive Summary & Core Value Proposition
[cite_start]**Lva** is a high-reliability, multi-tenant car wash booking and operations platform tailored specifically for the Armenian market[cite: 114]. 

[cite_start]While existing solutions like WashApp AM act as marketplace directories, they suffer from a major trust problem: *phantom availability*[cite: 115]. [cite_start]Users book a time slot in the mobile app but still find themselves waiting 30+ minutes at the physical service station due to desynchronized queues[cite: 115]. [cite_start]**Lva** solves this by unifying the B2C marketplace with a live, mandatory bay-management system controlled directly by the service provider's staff[cite: 116]. 

[cite_start]Furthermore, **Lva** is architected natively as an automated **Multi-Tenant SaaS Infrastructure**[cite: 117]. [cite_start]While it launches as a unified B2C aggregator, any car wash provider can seamlessly upgrade to have the system split, custom-branded, and deployed as a standalone native app running on independent infrastructure[cite: 118].

---

## 2. Competitive Edge & Market Adaptation (Lva vs. WashApp AM)

| Feature Dimension | WashApp AM | Lva (Our Solution) |
| :--- | :--- | :--- |
| **Slot Integrity** | [cite_start]High buffer/delayed entry issues; manual intervention[cite: 120]. | [cite_start]**Hardware-backed Real Time.** Tied directly to operator interaction + future IoT camera streams to eliminate wait times[cite: 121]. |
| **Map Engine** | [cite_start]Standard Maps + static ETA updates[cite: 122]. | [cite_start]**Yandex Maps API Optimization.** Custom route calculation with real-time Yerevan traffic congestion indices[cite: 122]. |
| **B2B Architecture** | [cite_start]Single-app multi-vendor listing only[cite: 123]. | [cite_start]**True Multi-Tenancy.** Clean structural division allowing single-tenant white-label deployments down the road[cite: 123]. |
| **Loyalty & Monetization** | [cite_start]Basic static cashback points (WashPoints)[cite: 124]. | [cite_start]**Contextual & Climate-Driven Gamification.** Automatic weather-based dynamic pricing and discount drops[cite: 124]. |

---

## 3. Scope of the MVP vs. Future Roadmap

### Phase 1: MVP Focus (B2C Marketplace Aggregator)
* [cite_start]Full feature parity with WashApp AM (Yandex map integration, live ETAs, garage management, slots booking)[cite: 125].
* [cite_start]Digital payments natively configured for the Armenian financial landscape (ArCa, Idram, Telcell)[cite: 126].
* [cite_start]Real-time slot validation using a dedicated Moderator Tablet App for the washers[cite: 126].
* [cite_start]Weather-based dynamic automated discounting logic[cite: 127].
* [cite_start]B2C Multi-Car Subscriptions and Corporate Account block-booking reserves[cite: 127].

### Phase 2: Connected Infrastructure (Non-MVP)
* [cite_start]**Live Stream Progress Cameras:** Integration of RTSP/HLS video feeds from washing bays into the client booking screen[cite: 128].
* [cite_start]**White-Label Pipeline Automation:** Scripted generation to build and push independent single-customer branded mobile applications from the core codebase[cite: 129].

---

## 4. System Architecture & Multi-Tenant Strategy

[cite_start]To ensure that the application can be seamlessly split and deployed for single corporate clients without rewritten code, **Lva** implements a **Database Schema Isolation Layer** using a strict `tenant_id` strategy[cite: 130].

| Application Component | Target State Layer | Database Strategy |
| :--- | :--- | :--- |
| **Lva B2C Aggregator (Marketplace)** | App Store / Google Play | [cite_start]Queries records globally where `tenant_id IS NULL` (All Partners)[cite: 132, 133]. |
| **White-Label Client (Standalone App)** | Custom Single-Client Build | [cite_start]A global compilation build flag hardcodes their specific token: `tenant_id = 'XYZ'`[cite: 133]. |

* [cite_start]**Data Isolation:** Every core database table configuration (`bays`, `bookings`, `prices`, `staff`) contains a nullable `tenant_id` column[cite: 131].
* [cite_start]**Independent Routing:** When compiled for an independent brand, the app exclusively serves that client's parameters, ignoring the marketplace entirely while utilizing the exact same backend engine[cite: 134].

---

## 5. Functional Requirements by Application Component

### 5.1 Client Mobile Application (iOS & Android)

#### A. Interactive Map & Deep Yandex Integration
* [cite_start]**FR-1.1:** The app must render an interactive map powered by the Yandex Maps SDK[cite: 135].
* [cite_start]**FR-1.2:** Car wash pins must alter color dynamically based on state: Green (Slots open in < 15 mins), Yellow (Slots open in < 1 hr), Red (Fully Booked)[cite: 136].
* [cite_start]**FR-1.3:** Display exact travel time (ETA) to the selected car wash by processing current Yerevan traffic levels using Yandex Routing API parameters[cite: 137].

#### B. The "Zero-Wait" Dynamic Booking Engine
* [cite_start]**FR-2.1:** Users must configure a "Garage" profile saving vehicles classified by size (Sedan, Crossover, SUV, Coupe)[cite: 138].
* [cite_start]**FR-2.2:** Booking slots must change duration dynamically based on selected vehicle volume (e.g., Sedan Exterior = 25 minutes; SUV Exterior + Interior = 45 minutes)[cite: 139].
* [cite_start]**FR-2.3:** The app must enforce a **3-Tap Booking flow**: Open App $\rightarrow$ Tap Saved Car on Nearest Wash Pin $\rightarrow$ Confirm[cite: 140].

#### C. Smart Climate-Driven Loyalty & Subscription Tiers
* [cite_start]**FR-3.1:** **Weather Integration:** Connect with local weather provider APIs[cite: 141]. [cite_start]If precipitation probability in Yerevan is $>70\%$ over the next 24 hours, trigger a push notification offering interior-only cleaning or conditioning packages at a discount[cite: 142].
* [cite_start]**FR-3.2:** **Monthly B2C Pass:** Enable users to purchase a discounted recurring bundle (e.g., 5 premium washes valid for 30 days)[cite: 143].
* [cite_start]**FR-3.3:** **Anonymized Corporate Reserve:** Support B2B corporate profiles where a company buys a block booking slot (e.g., "Every Wednesday, Bay 1 from 14:00 to 18:00 is reserved for company employees")[cite: 144]. [cite_start]The reservation remains open to any staff member without hard-assigning a single license plate upfront[cite: 145].

#### D. Future Feature: Live Process Stream (Phase 2)
* [cite_start]**FR-4.1:** Once a booking status transitions to "Washing", the client app must open an inline HLS/RTSP video player card showing the real-time CCTV camera feed stream of that assigned bay[cite: 146].

---

### 5.2 Car Washing Service App (Moderator Tablet App)

[cite_start]This interface runs on low-cost Android/iOS tablets mounted at the physical washing bays[cite: 147]. [cite_start]It serves as the single source of truth for scheduling availability[cite: 148].

| Interface Interaction | System Action Event | Target State Outcome |
| :--- | :--- | :--- |
| **One-Tap Framework** | [cite_start]Operator selects: `Arrived`, `Start Wash`, `Finishing`, or `Completed`[cite: 149]. | [cite_start]Pushes immediate status web-sockets updates to the Client App[cite: 149]. |
| **Walk-In Log Override** | [cite_start]Operator selects: `+ Walk-In Log` button[cite: 150]. | [cite_start]Generates an instant offline block on the central server to prevent overbooking[cite: 151]. |

---

### 5.3 Admin Web Application & Corporate Portal

#### A. Wash Owner Dashboard
* [cite_start]**FR-6.1:** Define and update pricing structures dynamically linked to vehicle size tiers[cite: 152].
* [cite_start]**FR-6.2:** Real-time analytics view: Revenue splits categorized by Payment Channel (Cash vs. App Wallet vs. Corporate Settlements)[cite: 153].

#### B. Super Admin Fleet Portal
* [cite_start]**FR-7.1:** Manage B2B Corporate invoicing, allowing company fleets (e.g., delivery systems, banks) a post-paid balance structure with automated monthly billing cycles[cite: 154].
* [cite_start]**FR-7.2:** **White-Label Asset Management:** A configuration dashboard to store asset URLs (Logo SVGs, Theme Color Hex Codes) for single-tenant clients when generating their standalone applications[cite: 155].

---

## 6. Non-Functional Requirements (NFRs)

* [cite_start]**Performance & Sync:** Booking confirmations or walk-in blocks must sync and update globally within $\le 1.5$ seconds across the Client App map and Moderator Panel to prevent slot overlapping[cite: 156].
* [cite_start]**Offline Resilience (Moderator App):** If internet connectivity drops at the car wash station, the Moderator App must cache state changes locally and dump state synchronization payloads to the server immediately upon reconnection[cite: 157].
* [cite_start]**Localization:** System interfaces must offer full localization capabilities in three target languages: **Armenian, Russian, and English**[cite: 158].