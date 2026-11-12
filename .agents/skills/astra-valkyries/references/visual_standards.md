# 🎨 Visual Standards & Procedural Vector Rendering

Astra Valkyries rejects generic low-resolution raster packs and blurry stretched textures. The game aims for the clean, knife-sharp vector cyber-aerospace aesthetic pioneered by *Nova Drift*, combined with the vibrant atmospheric depth of *Dead Cells* and *Risk of Rain*.

---

## 1. Vector-First Megastructures & Props

All props, walls, space stations, and environment obstacles must be procedurally drawn using vector geometry:

* **Aerospace Armor Plating**:
  - Laser-cut, chamfered corner geometry instead of plain rectangles.
  - Multi-tone panel fills (e.g., deep charcoal slate base `#0E141C` with lighter titanium reinforced plates `#1D2A3A`).
  - Rivet lines spaced at regular intervals along structural seams.
* **Industrial Hazard Markings**:
  - Crisp 45-degree diagonal hazard warning chevrons (amber/black `#FFD600` / `#111111`) on industrial bulkheads and fusion cells.
* **Plasma Conduits & Energy Cores**:
  - Recessed conduit channels with glowing center plasma lines.
  - Core nodes with pulsating multi-layer halos using `BlendMode.plus`.

---

## 2. Glowing Energy & Particle Bloom

Bloom in Astra Valkyries is achieved via efficient additive layer blending using [`lib/game/glow.dart`](../../../../lib/game/glow.dart):

* **Neon Outlines (`Glow.strokePath`)**:
  - Core solid line + 2 outer semi-transparent wide passes drawn with `BlendMode.plus`.
* **Energy Orbs (`Glow.orb`)**:
  - Multi-radius concentric circles scaling down to an ultra-bright white-hot core.
* **Sparks & Debris (`Glow.spark`)**:
  - Lightweight single-pass spark rendering with decay alpha.

---

## 3. Cosmic Backdrops & Void Shading

Never use stretched 720p/1080p raster JPEGs for space backgrounds.
* **Deep Cosmic Void**:
  - Dark biome-specific vertical/radial radial color gradients (e.g., deep indigo for Asteroid Belt, abyssal violet for Event Horizon, fiery ember-black for Magma Sector).
* **Volumetric Gas Clouds**:
  - Parallax radial gradient nebulas drawn with `BlendMode.plus` that drift at distinct depth speeds ($0.05\times$ to $0.15\times$ player velocity).
* **Space Dust & Starlight**:
  - Multi-layer starfield motes drifting with camera movement to communicate ship inertia and velocity.

---

## 4. Legibility & Projectile Contrast

In moments with 100+ entities:
* **Enemy Bullets**: Must have an outer bright red/magenta glowing stroke (`#FF1744` or `#FF0055`) with a pure white center `#FFFFFF` to ensure 100% visibility over dark cosmic nebulas and bright explosions.
* **Telegraph Lines**: High-damage enemy attacks (Snipers, Boss Beams) must project a crisp telegraphed laser line for 600–800ms before firing, shifting color from amber to pure neon crimson at the moment of discharge.
