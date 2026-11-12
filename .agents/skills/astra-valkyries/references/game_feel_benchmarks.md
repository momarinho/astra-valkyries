# 🕹️ Game Feel & Commercial Benchmarks

To achieve the visceral, addictive quality of top commercial indie titles, Astra Valkyries incorporates specific mechanics calibrated against world-class references:

---

## 1. Hades: Frame-Level Impact & Responsiveness

* **Scaled Hit-Stop (Micro-Freezes)**:
  - Critical hits and heavy explosions trigger micro hit-stops ($30\text{ms}$ to $80\text{ms}$).
  - Hit-stop must freeze gameplay updates while allowing particle drift or camera shake to emphasize weapon weight.
* **Directional Screenshake**:
  - Screenshake must not be pure noise; it decays along the vector of the impact force.
  - High-impact railguns push the camera slightly back along the firing line.
* **Input Buffering**:
  - Dash and Ultimate inputs are buffered for $100\text{ms}$–$120\text{ms}$ during animation recoveries or hit-stops, ensuring zero dropped player actions.

---

## 2. Nova Drift: Thrust Inertia & Tactical Telegraphs

* **Tactile Ship Physics**:
  - Ships must feel distinct: Lyra (nimble, instant vector redirection), Selene (balanced, smooth drift), Vesper (heavy kinetic inertia, high top speed).
  - Thruster flame trails dynamically lengthen and intensify during active thrust.
* **Telegraphed High-Caliber Attacks**:
  - Snipers, dreadnoughts, and beam turrets must project a narrow targeting guide ($600\text{ms}$ to $800\text{ms}$) that locks angle shortly before firing, allowing skilled reflex dodging.

---

## 3. Dead Cells: Kinetic Aggression & Elite Affixes

* **Kill Momentum**:
  - Rapid multi-kills reward temporary movement speed or firing rate buffs to encourage aggressive forward positioning.
* **Elite Enemy Modifiers**:
  - Elites possess tactical affixes:
    - *Gravitational Well*: Drags nearby player and projectiles.
    - *Overcharged Shield*: Directional frontal barrier requiring flanking.
    - *Volatile Core*: Explodes into a radial burst of shrapnel on death.

---

## 4. Classic Shmups: Choreographed Squadrons

* **Tactical Spawns vs Random Spawn Clutter**:
  - Enemies do not merely pop up randomly at screen borders.
  - Squads spawn in choreographies:
    - **Wedge Formation (V-Formation)**: Fast scouts flanking a lead fighter.
    - **Pincer Cerco**: Two wings entering from opposite screen borders.
    - **Freight Escort**: Heavy cargo hauler protected by escort interceptors.
