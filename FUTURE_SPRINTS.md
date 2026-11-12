# 🚀 Astra Valkyries: Production Sprints Roadmap (Sprints 55 – 60)

This document outlines the current active engineering milestones for **Astra Valkyries: Void Protocol**, aligned with the official roadmap in [`docs/ROADMAP_SPRINTS.md`](docs/ROADMAP_SPRINTS.md) and our development skill standard.

---

## 🏆 Completed Sprints

### ✅ Sprint 55: Visual Purification & Procedural Vector Megastructures
- Eradicated low-res raster textures and replaced breakable props with procedural vector renderers (`FusionBarrels`, `OreCrystals`, `CargoCrates`).
- High-definition procedural armor plating for `MegastructureWallComponent` with hazard stripes and conduits.
- 8 automated tests in `test/sprint55_visual_purification_test.dart`.

### ✅ Sprint 55.5: Flutter 3.50 Modernization, Zero-GC Hardening & Open-Source Pivot
- Upgraded project to **Flutter 3.50.0 Stable** and **Dart 3.14.0**.
- Zero-warning linter standard (0 issues in `flutter analyze`).
- Replaced Flame's $O(N)$ `whereType` scans with $O(1)$ Entity Registry sets (`activeEnemies`, `activeAsteroids`, `activeDrops`, `activeStations`).
- Added real-time FPS & diagnostic counter in Settings and HUD with exponential smoothing.
- Replaced legacy content with 10 high-resolution **Tactical Mission Dossiers**.
- Created clean open-source release on GitHub (`momarinho/astra-valkyries`) under the **MIT License**.
- 280 automated tests passing with 100% green status.

---

## 🎯 Active & Upcoming Sprints

### 🌌 Sprint 56: Cosmic Atmosphere, Directional Star Lighting & Kinetic Space Dust (*Nova Drift Standard*)
- **Target:** Eradicate disconnected visual elements; establish cohesive deep space visual atmosphere.
- **Deliverables:**
  - `KineticSpaceDustComponent`: 250 multi-depth cosmic dust motes stretching proportionally to player velocity vector.
  - Directional normal-simulated lighting on `AsteroidComponent` computed against the sector star's position ($\hat{N} \cdot \vec{L}_{\text{sun}}$).
  - Procedural multi-layer parallax cosmic dust and volumetric gas drifts.
  - Distant capital ship debris silhouettes drifting at 12% camera speed with pulsing beacon lights.

### 🕹️ Sprint 57: Game Feel Visceral, Input Buffering & Hit-Stop Dinâmico (*Hades Standard*)
- **Target:** Eliminate dropped inputs and provide weighty, physical combat feel.
- **Deliverables:**
  - 120ms Universal Input Buffer for Dash and Special/Ultimate abilities.
  - Scaled hit-stop freeze frames ($0\text{ms}$ to $140\text{ms}$) calibrated by impact severity and critical strikes.
  - Inertial propulsion flame expansion responsive to real craft acceleration ($\Delta \vec{v} / \Delta t$).

### 👾 Sprint 58: Coreografia Tática de Esquadrões & Telegraphs Universais (*Nova Drift & Galaga*)
- **Target:** Intelligent enemy flight choreography and clear telegraphing.
- **Deliverables:**
  - Tactical squad spawn formations (Wedge Formation, Pincer Maneuver, Heavy Convoy Escort).
  - 700ms universal sniper and boss laser telegraphs with locking color transitions.
  - Boids Repulsion algorithm to prevent swarm enemy sprite overlap.

### ⚖️ Sprint 59: Expansão Roguelite, Trade-offs Radicais & Estatísticas (*Brotato Model*)
- **Target:** High-risk/high-reward build variety and transparent combat statistics.
- **Deliverables:**
  - Radical trade-off passives (*Glass Cannon Reactor*, *Juggernaut Plating*, *Unstable Payloads*).
  - Ordered level-up queue (`pendingLevelUps`) to handle massive XP spikes without losing perks.
  - Transparent pause-screen statistics dashboard (consolidated DPS, Armor, Crit, Speed).

### 🌐 Sprint 60: Deploy Online, Global Leaderboard Cloud & Web Playability (Zero VPS / Free-Tier Cloud)
- **Target:** Playable in any web browser without installation, backed by a free cloud leaderboard API.
- **Deliverables:**
  - Flutter Web compilation pipeline and automated **GitHub Pages** deployment via GitHub Actions.
  - Minimal multi-stage `Dockerfile` (~20MB) for `go-backend` ready for 1-click free deploy on Render.com or Fly.io (HTTPS included, zero cost).
  - Dynamic API base URL configuration in client with resilient offline-first fallback.
  - "Play in Browser" badge and one-click demo link in repository README.
