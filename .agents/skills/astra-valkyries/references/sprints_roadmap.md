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

## Sprint 56: Cosmic Atmosphere, Directional Star Lighting & Kinetic Space Dust (DONE ✅)
* **Goal**: Enrich biome depth with kinetic space dust and directional celestial rim-lighting.
* **Deliverables**:
  - `KineticSpaceDustComponent`: 250 multi-depth drift motes responsive to player velocity with dynamic speed line stretching.
  - Directional normal-simulated shading on `AsteroidComponent` based on local sector star position ($\hat{N} \cdot \vec{L}_{\text{sun}}$).
  - `ProceduralCosmicNebulaComponent`: Organic multi-lobe volumetric gas clouds in `BlendMode.plus` with differential rotation.
  - `DistantMegastructureBackdropComponent`: Capital ship and orbital ring silhouettes with 12% parallax and 2.5s beacon cycles.
  - `SpaceTimeWarpGridComponent`: Einsteinian cosmic coordinate warp grid curving toward gravity wells.
  - 7 automated tests in `test/sprint56_cosmic_atmosphere_test.dart` (287 total tests passing).

---

## Sprint 57: Hades-Grade Combat Feel & Tactile Inertia (DONE ✅)
* **Goal**: Frame-level impact, input buffering, and ship weight.
* **Deliverables**:
  - Universal 120ms Input Buffer for Dash and Special/Ultimate abilities (zero dropped inputs).
  - Scaled hit-stop micro-freezes ($0\text{ms}$ common, $35\text{ms}$ heavy, $70\text{ms}$ crit/katana, $140\text{ms}$ elite kill) with sprite micro-jiggle.
  - Inertia-driven dynamic thruster flame plume scaling with acceleration ($\vec{a} = \Delta \vec{v} / \Delta t$) and craft mass.
  - Zero-GC hot path hardening across `PlayerComponent` and `DashGhost`.
  - 7 automated tests in `test/sprint57_visceral_game_feel_test.dart` (294 total tests passing).

---

## Sprint 58: Tactical Squadron AI & High-Caliber Telegraphs (DONE ✅)
* **Goal**: Choreographed enemy formations and reflex-based counter-play.
* **Deliverables**:
  - Tactical squad spawn patterns (Wedge, Pincer, Freight Escort) in `AsteroidField`.
  - Universal 700ms laser telegraphs (500ms amber tracking -> 200ms crimson aim-lock) on Snipers, CryoBombers, Raiders, and Dreadnought Leviathan (Zero-GC).
  - Algorithmic swarm separation (Boids Repulsion via `game.activeEnemies`) preventing sprite overlap.
  - Bi-directional environmental hazards: enemy-triggered `ProximityMineComponent` & Dash-rammed kinetic asteroids crushing enemy ships.
  - 8 automated tests in `test/sprint58_tactical_ai_test.dart` (302 total tests passing).

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
