# 📋 Roadmap Sprints: Phase 11 (Commercial AAA Indie Polish)

This document tracks the execution of Sprints 55 to 60, as officially documented in [`docs/ROADMAP_SPRINTS.md`](../../../../docs/ROADMAP_SPRINTS.md).

---

## Sprint 55: Visual Purification & Procedural Vector Megastructures (DONE ✅)
* **Goal**: Purge all blurry, low-res Kenney raster assets and 768p stretched JPEGs.
* **Deliverables**:
  - Procedural vector renderers for breakable props (Fusion Barrels, Faceted Ore Crystals, Cargo Crates, EMP Cells).
  - High-definition aerospace armor plating for `MegastructureWallComponent` with hazard stripes, rivets, and glowing plasma conduits.
  - Vector runway landing decks and satellite communication dishes in `indoor_environment.dart`.
  - Deep procedural cosmic void with parallax gas clouds in `BiomeBackdropComponent`.
  - 8 new tests passing (`test/sprint55_visual_purification_test.dart`).

---

## Sprint 55.5: Flutter 3.50 Modernization, Zero-GC Hardening & Open-Source Pivot (DONE ✅)
* **Goal**: Upgrade stack to Flutter 3.50 / Dart 3.14, eliminate linter warnings, establish O(1) Entity Registry and sanitize repository for public portfolio.
* **Deliverables**:
  - Zero-warning linter standard (0 errors, 0 warnings, 0 lints in `flutter analyze`).
  - Pre-allocated entity registry sets in `AsteroidsGame` eliminating $O(N)$ `whereType` loops.
  - Interactive FPS & Telemetry switch in SettingsOverlay and HudOverlay.
  - Replaced legacy content with 10 high-resolution Tactical Mission Dossiers.
  - Published clean initial release to GitHub (`momarinho/astra-valkyries`) under MIT License.

---

## Sprint 56: Cosmic Atmosphere, Directional Star Lighting & Kinetic Space Dust (IN PROGRESS ⏳)
* **Goal**: Enrich biome depth with kinetic space dust and directional celestial rim-lighting.
* **Deliverables**:
  - `KineticSpaceDustComponent`: Multi-depth drift motes responsive to player velocity.
  - Directional normal-simulated shading on `AsteroidComponent` based on local sector star position.
  - Interactive volumetric nebula drift trails.

---

## Sprint 57: Hades-Grade Combat Feel & Tactile Inertia
* **Goal**: Frame-level impact, input buffering, and ship weight.
* **Deliverables**:
  - Frame-buffered Dash and Ultimate inputs (120ms buffer queue).
  - Scaled hit-stop ($30\text{ms}$–$80\text{ms}$) calibrated by weapon mass and critical hits.
  - Ship-specific inertia tuning and dynamic thruster flame expansion.

---

## Sprint 58: Tactical Squadron AI & High-Caliber Telegraphs
* **Goal**: Choreographed enemy formations and reflex-based counter-play.
* **Deliverables**:
  - Tactical squad spawn patterns (Wedge, Pincer, Freight Escort).
  - Telegraph laser lines for Snipers and Elites with countdown color transition.
  - Algorithmic swarm separation (Boids Repulsion) preventing sprite overlap.

---

## Sprint 59: Roguelite Expansion & Transparent Build Stats (Brotato Model)
* **Goal**: Deep tactical build diversity and high-risk trade-offs.
* **Deliverables**:
  - High-risk/high-reward passive modules (Glass Cannon, Juggernaut Plating, Unstable Payloads).
  - Ordered level-up queue (`pendingLevelUps`) to prevent lost cards during mass XP bursts.
  - Transparent pause-screen statistics dashboard (real DPS, Crit %, Armor %, Speed %).

---

## Sprint 60: Cloud Deploy & Web Playability (Zero VPS / Free-Tier Cloud)
* **Goal**: Playable directly in browser with automated GitHub Pages CI/CD and free cloud Go leaderboard.
* **Deliverables**:
  - Flutter Web compilation pipeline and automated GitHub Pages deployment via GitHub Actions.
  - Multi-stage minimal `Dockerfile` (~20MB) for `go-backend` ready for zero-cost deployment on Render.com / Fly.io.
  - Dynamic API base URL configuration in client with resilient offline-first fallback.
  - "Play in Browser" badge and one-click demo link in repository README.
