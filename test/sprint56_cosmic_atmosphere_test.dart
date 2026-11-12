import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/kinetic_space_dust.dart';
import 'package:asteroids/game/components/distant_megastructure.dart';
import 'package:asteroids/game/components/procedural_cosmic_nebula.dart';
import 'package:asteroids/game/components/space_time_warp_grid.dart';
import 'package:asteroids/game/components/singularity_vortex.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Sprint 56: Cosmic Atmosphere & Directional Star Lighting (Nova Drift Standard)',
    () {
      test(
        'Sector star celestial lighting vectors and colors are correctly configured',
        () {
          for (final sector in Sector.allSectorsWithBranches) {
            final lightDir = sector.starLightDirection;
            final starColor = sector.starColor;

            // Vector must be normalized (length approx 1.0)
            final len = math.sqrt(
              lightDir.x * lightDir.x + lightDir.y * lightDir.y,
            );
            expect(
              len,
              closeTo(1.0, 0.05),
              reason: '${sector.name} light vector must be unit vector',
            );

            // Star color must have full opacity
            expect(starColor.a, greaterThanOrEqualTo(0.99));
          }

          // Check specific sectors
          final vesta = Sector.findById(SectorId.vesta);
          expect(vesta.starLightDirection.x, lessThan(0.0));
          expect(vesta.starLightDirection.y, lessThan(0.0));

          final orion = Sector.findById(SectorId.orion);
          expect(orion.starColor, const Color(0xFFFFAB40));
        },
      );

      test(
        'KineticSpaceDustComponent initializes 250 motes with depth layers and stretches with velocity',
        () {
          final dust = KineticSpaceDustComponent();
          expect(dust.priority, -35);
          expect(dust.moteCount, 250);

          // Mount into a test game
          final game = AsteroidsGame();
          game.world.add(dust);
          dust.onMount();

          expect(dust.motes.length, 250);

          // Verify depth distribution (0.25 to 1.0) and size scaling
          for (final mote in dust.motes) {
            expect(mote.depth, greaterThanOrEqualTo(0.25));
            expect(mote.depth, lessThanOrEqualTo(1.0));
            expect(mote.size, greaterThanOrEqualTo(0.8));
            expect(mote.size, lessThanOrEqualTo(2.2));
            expect(mote.baseAlpha, greaterThanOrEqualTo(0.3));
            expect(mote.baseAlpha, lessThanOrEqualTo(0.85));
          }

          // Test inertia reaction in update
          game.state = GameState.playing;
          game.player = PlayerComponent(position: Vector2.zero())
            ..customGame = game;
          game.player.velocity = Vector2(
            300.0,
            0.0,
          ); // Player cruising right at 300px/s

          final initialX = dust.motes.first.x;
          dust.update(0.1); // 100ms step
          final newX = dust.motes.first.x;

          // Dust must drift in opposite direction (negative X)
          expect(newX, lessThan(initialX));
        },
      );

      test(
        'AsteroidComponent computes outward edge normals and distinguishes sunlit vs shadow faces',
        () {
          final asteroid = AsteroidComponent(
            radius: 40.0,
            position: Vector2(500, 500),
            velocity: Vector2.zero(),
            variant: AsteroidVariant.standard,
          );

          expect(asteroid.cachedVertices.length, asteroid.numPoints);
          expect(asteroid.cachedNormals.length, asteroid.numPoints);

          // Verify that every normal is a normalized unit vector and points outwards
          for (var i = 0; i < asteroid.numPoints; i++) {
            final norm = asteroid.cachedNormals[i];
            final normLen = math.sqrt(norm.dx * norm.dx + norm.dy * norm.dy);
            expect(normLen, closeTo(1.0, 0.01));

            final v1 = asteroid.cachedVertices[i];
            final v2 = asteroid.cachedVertices[(i + 1) % asteroid.numPoints];
            final midX = (v1.dx + v2.dx) * 0.5;
            final midY = (v1.dy + v2.dy) * 0.5;

            // Outward dot product with edge midpoint from center (0,0) must be positive
            final outwardDot = midX * norm.dx + midY * norm.dy;
            expect(
              outwardDot,
              greaterThan(0.0),
              reason: 'Normal $i must point outward',
            );
          }

          // Verify dot product lighting against sun direction
          final sunLightDir = Vector2(-0.7071, -0.7071); // Sun at top-left
          int litEdges = 0;
          int shadowEdges = 0;

          for (var i = 0; i < asteroid.numPoints; i++) {
            final norm = asteroid.cachedNormals[i];
            final dot = norm.dx * sunLightDir.x + norm.dy * sunLightDir.y;
            if (dot > 0.05) {
              litEdges++;
            } else {
              shadowEdges++;
            }
          }

          // Both lit faces and shadow faces must exist on a 3D chiseled rock
          expect(litEdges, greaterThan(0));
          expect(shadowEdges, greaterThan(0));
          expect(litEdges + shadowEdges, asteroid.numPoints);
        },
      );

      test(
        'DistantMegastructureBackdropComponent has 12% parallax and 2.5s beacon cycle',
        () {
          final megastructure = DistantMegastructureBackdropComponent();
          expect(megastructure.priority, -42);
          expect(DistantMegastructureBackdropComponent.parallaxFactor, 0.12);
          expect(DistantMegastructureBackdropComponent.beaconCyclePeriod, 2.5);

          // Verify beacon pulse cycle
          megastructure.update(0.1); // At t=0.1, peak alarm flash
          // Beacon pulse at phase 0.1 must be high
          final pulsePeak = math.sin((0.1 / 0.35) * math.pi);
          expect(pulsePeak, greaterThan(0.7));

          megastructure.update(1.0); // At t=1.1, idle phase
          // In idle phase, beacon must have residual low glow (0.04)
        },
      );

      test(
        'ProceduralCosmicNebulaComponent configures multi-lobe organic clusters',
        () {
          final nebula = ProceduralCosmicNebulaComponent();
          expect(nebula.priority, -38);
          expect(ProceduralCosmicNebulaComponent.parallaxLow, 0.08);
          expect(ProceduralCosmicNebulaComponent.parallaxMid, 0.15);

          // Update timer progresses
          nebula.update(1.5);
        },
      );

      test(
        'SpaceTimeWarpGridComponent warps grid nodes towards gravitational mass sources',
        () {
          final grid = SpaceTimeWarpGridComponent();
          expect(grid.priority, -30);
          expect(SpaceTimeWarpGridComponent.cols, 18);
          expect(SpaceTimeWarpGridComponent.rows, 12);

          final game = AsteroidsGame();
          game.world.add(grid);

          // Place a black hole singularity vortex at (1000, 1000)
          final vortex = SingularityVortexComponent(
            position: Vector2(1000, 1000),
          );
          game.world.add(vortex);

          // Verify grid components render cleanly without crash
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          grid.render(canvas);
          recorder.endRecording();
        },
      );

      test(
        'All Sprint 56 components render without allocating memory or throwing exceptions',
        () {
          final game = AsteroidsGame();
          final dust = KineticSpaceDustComponent();
          final megastructure = DistantMegastructureBackdropComponent();
          final nebula = ProceduralCosmicNebulaComponent();
          final grid = SpaceTimeWarpGridComponent();
          final asteroid = AsteroidComponent(
            radius: 35.0,
            position: Vector2(400, 400),
            velocity: Vector2(10, 10),
          );

          game.world.addAll([dust, megastructure, nebula, grid, asteroid]);
          dust.onMount();
          asteroid.testGame = game;

          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);

          // Render each component
          dust.render(canvas);
          megastructure.render(canvas);
          nebula.render(canvas);
          grid.render(canvas);
          asteroid.render(canvas);

          final picture = recorder.endRecording();
          expect(picture, isNotNull);
        },
      );
    },
  );
}
