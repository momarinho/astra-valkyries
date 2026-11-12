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

### ✅ Sprint 56: Cosmic Atmosphere, Directional Star Lighting & Kinetic Space Dust (*Nova Drift Standard*)
- Implemented `KineticSpaceDustComponent`: 250 multi-depth motes stretching into directional speed lines ($\vec{L} = -\vec{v}_{\text{player}} \cdot 0.045 \cdot z$).
- Directional normal-simulated star lighting on `AsteroidComponent` via dot product $\hat{N} \cdot \vec{L}_{\text{sun}}$ per polygon edge, adding brilliant rim highlights and deep cosmic shadows.
- `ProceduralCosmicNebulaComponent`: Multi-lobe organic volumetric gas clouds in `BlendMode.plus` with differential slow rotation and curved plasma filaments.
- `DistantMegastructureBackdropComponent`: Silhouettes of colossal derelict battleship (*Aegis Sovereign*) and orbital ring station drifting at 12% camera speed with 2.5s emergency beacon flash cycles.
- `SpaceTimeWarpGridComponent`: Einsteinian cosmic coordinate grid warping toward massive gravity wells (black holes, massive asteroids, sector bosses).
- 287 automated tests passing with 100% green status and 0 linter issues.

### ✅ Sprint 57: Game Feel Visceral, Input Buffering & Hit-Stop Dinâmico (*Hades Standard*)
- 120ms Universal Input Buffering in `PlayerComponent` and `AsteroidsGame` for Dash and Special/Ultimate actions.
- Scaled Hit-Stop system (`triggerScaledHitStop`): 0ms for common shots, 35ms for moderate hits (>= 45), 70ms for critical strikes / katana slices with micro-jiggle, 140ms for elite kills with directional shake.
- Physics-driven dynamic propulsion plume responsive to real craft acceleration ($\Delta \vec{v} / \Delta t$) with ship mass scaling (Astraea wide fusion plume, Lyra sharp afterburner).
- Zero-GC hardening across hot path renderers (`PlayerComponent`, `DashGhost`).
- 294 automated tests passing with 100% green status and 0 linter issues.

### 👾 Sprint 58: Coreografia Tática de Esquadrões & Telegraphs Universais (*Nova Drift & Galaga*) ✅ (CONCLUÍDA)
- Choreographed squadrons (`buildWedgeFormation`, `buildPincerManeuver`, `buildFreightEscort`) in `AsteroidField`.
- Universal 700ms laser telegraphs with 200ms aim-lock & amber-to-crimson shift on `EnemyShipComponent` and `DreadnoughtLeviathanComponent` (Zero-GC).
- Zero-GC Boids Repulsion (`applyBoidsSeparation`) over `game.activeEnemies` + bi-directional `ProximityMineComponent` & Dash-rammed kinetic asteroid crushing.
- 302 automated tests passing (`test/sprint58_tactical_ai_test.dart`) with 0 linter issues.

### ⚖️ Sprint 59: Expansão Roguelite, Trade-offs Radicais & Estatísticas (*Brotato Model*) ✅ (CONCLUÍDA)
- Expanded passives from 5 to 16 in `RoguePerkGenerator.buildPassiveCatalog()` with 3 Brotato radical trade-offs (*Glass Cannon*, *Juggernaut Plating*, *Unstable Payloads*).
- Ordered `pendingLevelUps` queue on `AsteroidsGame.addXp()` with `LevelUpOverlay` queue & trade-off badges.
- Real combat hooks (`armorReduction`, `rogueCritMultiplier`, `rogueLifesteal`, `rogueAreaMultiplier`, `rogueLuckBonus`) + `BuildStatsSnapshot` and `📊 STATS` tab in `PauseOverlay`.
- 309 automated tests passing (`test/sprint59_roguelite_expansion_test.dart`) with 0 linter issues.

---

## 🎯 Active & Upcoming Sprints

### 🌐 Sprint 60: Deploy Online, Global Leaderboard Cloud & Web Playability (Zero VPS / Free-Tier Cloud)
- **Target:** Playable in any web browser without installation, backed by a free cloud leaderboard API.
- **Deliverables:**
  - Flutter Web compilation pipeline and automated **GitHub Pages** deployment via GitHub Actions.
  - Minimal multi-stage `Dockerfile` (~20MB) for `go-backend` ready for 1-click free deploy on Render.com or Fly.io (HTTPS included, zero cost).
  - Dynamic API base URL configuration in client with resilient offline-first fallback.
  - "Play in Browser" badge and one-click demo link in repository README.
