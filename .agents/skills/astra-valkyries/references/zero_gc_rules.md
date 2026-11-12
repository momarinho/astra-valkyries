# ⚡ Zero-GC Rules & Hot Path Optimization

In a 60–120 FPS game, memory allocations inside `update(dt)` and `render(canvas)` trigger Garbage Collection (GC) pauses that cause noticeable micro-stutter (frame jank). This guide details the mandatory patterns for zero-allocation coding in Astra Valkyries.

---

## 1. Paint Instantiation: The Static / Cached Pattern

### ❌ BANNED (Allocates native finalizers 60 times/sec per entity):
```dart
@override
void render(Canvas canvas) {
  final fillPaint = Paint()
    ..color = Colors.cyan
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset.zero, 20, fillPaint);
}
```

### ✅ APPROVED (Zero allocations, mutated in place):
```dart
class MyComponent extends PositionComponent {
  // Option A: Component-level pre-allocated field
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  // Option B: Shared static final cache (ideal for identical or palette-based draws)
  static final Paint _sharedStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  @override
  void render(Canvas canvas) {
    _fillPaint.color = isFlashing ? Colors.white : Colors.cyan;
    canvas.drawCircle(Offset.zero, 20, _fillPaint);

    _sharedStrokePaint.color = Colors.cyanAccent;
    _sharedStrokePaint.strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, 20, _sharedStrokePaint);
  }
}
```

*Reference implementation*: Inspect [`lib/game/glow.dart`](../../../../lib/game/glow.dart) for clean static Paint pools.

---

## 2. Geometry & Paths: The Scratch Path Pattern

### ❌ BANNED:
```dart
@override
void render(Canvas canvas) {
  final path = Path()
    ..moveTo(0, -10)
    ..lineTo(10, 10)
    ..close();
  canvas.drawPath(path, _paint);
}
```

### ✅ APPROVED:
```dart
class MyComponent extends PositionComponent {
  // Reusable scratch path
  final Path _scratchPath = Path();

  @override
  void render(Canvas canvas) {
    _scratchPath.reset();
    _scratchPath.moveTo(0, -10);
    _scratchPath.lineTo(10, 10);
    _scratchPath.close();
    canvas.drawPath(_scratchPath, _sharedPaint);
  }
}
```

---

## 3. Vector2 Math: In-Place Mutations

### ❌ BANNED:
```dart
@override
void update(double dt) {
  // Creates 3 temporary Vector2 instances on the heap every frame!
  final target = player.position;
  final diff = target - position;
  final move = diff.normalized() * (speed * dt);
  position += move;
}
```

### ✅ APPROVED:
```dart
class EnemyComponent extends PositionComponent {
  static final Vector2 _scratchDir = Vector2.zero();

  @override
  void update(double dt) {
    _scratchDir.setFrom(player.position);
    _scratchDir.sub(position);
    if (_scratchDir.length2 > 0.001) {
      _scratchDir.normalize();
      position.addScaled(_scratchDir, speed * dt);
    }
  }
}
```

---

## 4. Entity Registry: Replacing `world.children.whereType`

Flame's `children.whereType<T>()` iterates over every entity in `world.children` (hundreds of components). Never call it in game loops.

### ❌ BANNED:
```dart
@override
void update(double dt) {
  for (final enemy in game.world.children.whereType<EnemyShipComponent>()) {
    // Heavy full-collection filter executed 60 times/sec per caller!
  }
}
```

### ✅ APPROVED:
Maintain typed sets in `AsteroidsGame` managed via lifecycle hooks:

```dart
// In AsteroidsGame:
final Set<EnemyShipComponent> activeEnemies = <EnemyShipComponent>{};
final Set<AsteroidComponent> activeAsteroids = <AsteroidComponent>{};
final Set<DropComponent> activeDrops = <DropComponent>{};

// In EnemyShipComponent:
@override
void onMount() {
  super.onMount();
  game.activeEnemies.add(this);
}

@override
void onRemove() {
  game.activeEnemies.remove(this);
  super.onRemove();
}

// In caller:
@override
void update(double dt) {
  for (final enemy in game.activeEnemies) {
    // Direct O(1) set iteration, zero allocations, zero filtering!
  }
}
```

---

## 5. Flutter HUD Decoupling: Push Telemetry

Never use high-frequency polling tickers with `setState(() {})` in the Flutter HUD.

### ❌ BANNED:
```dart
_ticker = createTicker((elapsed) {
  if (_accumulator >= 0.033) {
    setState(() {}); // Rebuilds 2,700 lines of widgets 30 times a second!
  }
});
```

### ✅ APPROVED:
```dart
// In PlayerComponent / AsteroidsGame:
final ValueNotifier<double> hpNotifier = ValueNotifier<double>(1.0);
final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);

// In HUD Widget:
ValueListenableBuilder<double>(
  valueListenable: game.hpNotifier,
  builder: (context, hp, child) {
    return HealthBarWidget(hpPercent: hp);
  },
);
```
Only the specific gauge or counter repaints when value updates occur.
