---
name: astra-valkyries
description: >
  REQUIRED for all development, feature implementation, refactoring, performance optimization, and architectural decisions in Astra Valkyries (Flutter + Flame Action Roguelite).
  Use when creating or modifying components, weapons, enemies, bosses, biomes, HUD, audio, or game systems.
  Enforces Zero-GC game loop performance rules, procedural vector rendering standards, commercial benchmark alignment (Nova Drift, Hades, Dead Cells, Vampire Survivors), and sprint roadmap adherence.
---

# 🛸 Astra Valkyries — Master Agent Skill & Architecture Guide

Astra Valkyries is a commercial-grade, multiplatform **Roguelite Top-Down Space Shooter / Bullet Heaven Híbrido** developed in **Flutter 3 + Flame Engine 1.x**. Targets include Steam (PC/Linux, Steam Deck 60–120 FPS) and Nintendo Switch.

Whenever you work on this project, you operate as a **Lead Game Designer & Technical Game Architect**. You must balance high-octane sensory game feel (*Hades*, *Dead Cells*) with deep modular synergies (*Nova Drift*, *Vampire Survivors*) and strict native game engine performance discipline.

---

## ⚡ The 5 Non-Negotiable Core Laws

Every line of code written in Astra Valkyries must satisfy these 5 architectural laws:

### 1. Zero-Allocation Hot Path (Zero-GC Game Loop)
The `update(double dt)` and `render(Canvas canvas)` methods execute 60 to 120 times per second for every entity.
- **NEVER** instantiate `Paint()`, `Path()`, `Vector2()`, `Rect`, `List`, or closures inside `render()` or `update()`.
- Use `static final` or pre-allocated instance `Paint`s and mutate their properties (`.color = ...`, `.strokeWidth = ...`).
- Reuse mutable paths (`_scratchPath..reset()`) instead of allocating new `Path()` instances.
- Pre-allocate scratch vectors for physics and math (`Vector2.zero()`, mutate in place with `.setValues()` or `.addScaled()`).
- *Reference*: [`references/zero_gc_rules.md`](references/zero_gc_rules.md)

### 2. $O(1)$ Entity Registration (Zero `whereType` in Game Loops)
- **NEVER** run `world.children.whereType<T>()` or `List.from(...)` in `update()` or per-frame methods.
- Components register themselves in dedicated sets in `AsteroidsGame` upon `onMount()` and unregister on `onRemove()`:
  - `game.activeEnemies.add(this)` / `.remove(this)`
  - `game.activeAsteroids.add(this)` / `.remove(this)`
  - `game.activeDrops.add(this)` / `.remove(this)`
- Queries must be $O(1)$ direct collection lookups or localized spatial partitions.

### 3. Reactive Push HUD (Decoupled UI Boundary)
- The Flutter widget tree (`HudOverlay`) must **NEVER** poll the game loop using `setState()` in high-frequency tickers.
- Telemetry flows from Flame to Flutter via reactive, granular notifiers (`ValueNotifier<T>`).
- Wrap individual UI nodes (HP bar, shield gauge, score counter) in `ValueListenableBuilder`.
- High-frequency visual telemetry (e.g., Radar Scope) must be drawn directly via Flame canvas or a standalone `CustomPainter` wrapped in `RepaintBoundary`.

### 4. High-Definition Vector-First Visuals (Purified Aesthetic)
- **NEVER** introduce low-resolution, blurry, or stretched raster sprites (e.g. 768p JPEGs or pixelated CC0 Kenney tiles).
- Megastructures, station modules, props, and backdrops must be rendered with crisp procedural vector geometry:
  - Laser-cut chamfered aerospace armor plating.
  - Segmented rivet seams, caution hazard stripes, and glowing plasma conduits.
  - Multi-layered additive neon glows via [`lib/game/glow.dart`](../../../../lib/game/glow.dart) (`BlendMode.plus`).
- *Reference*: [`references/visual_standards.md`](references/visual_standards.md)

### 5. Zero-Regression Test Mandate (100% Green Suite)
- Astra Valkyries maintains a robust automated test suite (273+ tests).
- Every new feature, weapon, enemy, or optimization must include automated tests in `test/`.
- No task is complete until `flutter test` passes with 100% success and 0 failures.

---

## 📚 Deep Topic References

Detailed implementation guidelines and specifications:

- **[`zero_gc_rules.md`](references/zero_gc_rules.md)**: Concrete code patterns for Paint pooling, scratch paths, vector math, and entity registries.
- **[`visual_standards.md`](references/visual_standards.md)**: Guidelines for procedural vector rendering, biome lighting, space dust, and megastructure details.
- **[`game_feel_benchmarks.md`](references/game_feel_benchmarks.md)**: Specifications for hit-stop, directional screenshake, input buffering, squad AI, and telegraphing lasers.
- **[`sprints_roadmap.md`](references/sprints_roadmap.md)**: Sprint backlog, Phase 11 milestones (Sprints 55 to 60), and definition of done.

---

## 🛠️ Verification & Runbooks

### 1. Run All Tests
```bash
flutter test
```

### 2. Audit Codebase for Performance Anti-Patterns
Run the automated performance audit script to ensure no forbidden allocations were introduced:
```bash
.agents/skills/astra-valkyries/scripts/audit_performance.sh
```

### 3. Check Git Status & Formatting
```bash
git status
dart format --output=none --set-exit-if-changed lib/ test/
```
