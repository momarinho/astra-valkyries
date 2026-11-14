import 'dart:ui' show PictureRecorder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/components/asteroid.dart';
import 'package:void_protocol/game/components/asteroid_field.dart';
import 'package:void_protocol/game/components/dreadnought_leviathan.dart';
import 'package:void_protocol/game/components/enemy_ship.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/components/proximity_mine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Sprint 58: Tactical Squadron AI, Universal Telegraphs & Bi-Directional Hazards',
    () {
      test(
        'Choreographed Wedge Formation places 1 Raider leader + 4 symmetric Scouts in V',
        () {
          final origin = Vector2(1000, 1000);
          final approachDir = Vector2(0, 1); // Moving downward
          final specs = AsteroidField.buildWedgeFormation(
            origin: origin,
            approachDir: approachDir,
            spacing: 50.0,
          );

          expect(specs.length, 5);
          expect(specs.first.type, EnemyType.raider);
          expect(specs.first.position.x, closeTo(1000.0, 0.01));
          expect(specs.first.position.y, closeTo(1000.0, 0.01));

          final scouts = specs.skip(1).toList();
          expect(scouts.every((s) => s.type == EnemyType.scout), isTrue);

          // All scouts trail behind leader (smaller y) and form symmetric left/right pairs
          for (final s in scouts) {
            expect(s.position.y, lessThan(origin.y));
          }
          expect([
            scouts[0].position.x,
            scouts[1].position.x,
          ], containsAll([950.0, 1050.0]));
          expect([
            scouts[2].position.x,
            scouts[3].position.x,
          ], containsAll([900.0, 1100.0]));
        },
      );

      test(
        'Choreographed Pincer Maneuver spawns two opposite squads flanking player escape vector',
        () {
          final playerPos = Vector2(1200, 1200);
          final playerVel = Vector2(200, 0); // Moving +X
          final specs = AsteroidField.buildPincerManeuver(
            playerPos: playerPos,
            playerVel: playerVel,
            forwardLead: 250.0,
            flankDistance: 360.0,
          );

          expect(specs.length, 6);
          final leftFlank = specs.take(3).toList();
          final rightFlank = specs.skip(3).toList();

          // Player moves along +X, so flanking quadrants sit symmetrically on -Y and +Y
          for (final member in leftFlank) {
            expect(member.position.y, lessThan(playerPos.y - 250.0));
          }
          for (final member in rightFlank) {
            expect(member.position.y, greaterThan(playerPos.y + 250.0));
          }
          expect(leftFlank.first.type, EnemyType.raider);
          expect(rightFlank.first.type, EnemyType.raider);
        },
      );

      test(
        'Choreographed Freight Escort shields CarrierHive/Elite behind 2 frontal AegisBulwarks',
        () {
          final origin = Vector2(1000, 1000);
          final approachDir = Vector2(1, 0);
          final specs = AsteroidField.buildFreightEscort(
            origin: origin,
            approachDir: approachDir,
            useEliteFlagship: false,
          );

          expect(specs.length, 3);
          expect(specs[0].type, EnemyType.carrierHive);
          expect(specs[1].type, EnemyType.aegisBulwark);
          expect(specs[2].type, EnemyType.aegisBulwark);

          // Both Aegis cruisers sit ahead (+X) of the Carrier on opposite lateral offsets
          expect(specs[1].position.x, greaterThan(specs[0].position.x));
          expect(specs[2].position.x, greaterThan(specs[0].position.x));
          expect(specs[1].position.y, lessThan(specs[0].position.y));
          expect(specs[2].position.y, greaterThan(specs[0].position.y));
        },
      );

      test(
        'Universal 700ms Laser Telegraph tracks for 500ms (amber) then locks aim in final 200ms (crimson)',
        () {
          final enemy =
              EnemyShipComponent(
                  position: Vector2(500, 500),
                  type: EnemyType.sniper,
                )
                ..isTelegraphingShot = true
                ..shotTelegraphTimer =
                    EnemyShipComponent.universalTelegraphDuration
                ..lockedShotDir = Vector2(1, 0);

          // Phase 1 (first 400ms, remaining = 300ms > 200ms): aim updates & color is amber
          expect(enemy.isTelegraphAimLocked, isFalse);
          expect(enemy.currentTelegraphColor, const Color(0xFFFFB300));

          final firedEarly = enemy.advanceShotTelegraph(0.40, Vector2(0, 1));
          expect(firedEarly, isFalse);
          expect(enemy.shotTelegraphTimer, closeTo(0.30, 0.001));
          expect(enemy.lockedShotDir.y, closeTo(1.0, 0.01));

          // Enter final 200ms lock window (advance 150ms -> 150ms remaining <= 200ms)
          final firedAtLock = enemy.advanceShotTelegraph(0.15, Vector2(-1, 0));
          expect(firedAtLock, isFalse);
          expect(enemy.isTelegraphAimLocked, isTrue);
          expect(enemy.currentTelegraphColor, const Color(0xFFFF1744));

          // Even if target dodges sideways during the last 200ms, aim stays strictly locked!
          final dirBeforeDodge = enemy.lockedShotDir.clone();
          final firedFinal = enemy.advanceShotTelegraph(0.05, Vector2(1, 0));
          expect(firedFinal, isFalse);
          expect(enemy.lockedShotDir.x, closeTo(dirBeforeDodge.x, 0.001));
          expect(enemy.lockedShotDir.y, closeTo(dirBeforeDodge.y, 0.001));

          // Final 110ms finishes the 700ms window and triggers fire
          final firedEnd = enemy.advanceShotTelegraph(0.11, Vector2(1, 0));
          expect(firedEnd, isTrue);
          expect(enemy.isTelegraphingShot, isFalse);
        },
      );

      test(
        'Boids Separation algorithm pushes apart overlapping swarmers smoothly without NaN',
        () {
          final s1 = EnemyShipComponent(
            position: Vector2(500, 500),
            type: EnemyType.voidSwarmer,
          );
          final s2 = EnemyShipComponent(
            position: Vector2(510, 500),
            type: EnemyType.voidSwarmer,
          );

          final pair = [s1, s2];
          s1.applyBoidsSeparation(pair);
          s2.applyBoidsSeparation(pair);

          // s1 must be pushed toward -X away from s2 (+X)
          expect(s1.velocity.x, lessThan(0.0));
          expect(s2.velocity.x, greaterThan(0.0));

          // Exact zero-distance pair must still separate in opposite finite directions
          final sTwinA = EnemyShipComponent(
            position: Vector2(700, 700),
            type: EnemyType.voidSwarmer,
          );
          final sTwinB = EnemyShipComponent(
            position: Vector2(700, 700),
            type: EnemyType.voidSwarmer,
          );
          final twins = [sTwinA, sTwinB];
          sTwinA.applyBoidsSeparation(twins);
          sTwinB.applyBoidsSeparation(twins);
          expect(sTwinA.velocity.length.isFinite, isTrue);
          expect(sTwinA.velocity.length, greaterThan(0.0));
          expect(sTwinA.velocity.dot(sTwinB.velocity), lessThan(0.0));
        },
      );

      test(
        'Bi-Directional ProximityMine arms and detonates when enemy ships enter proximity',
        () {
          final mine = ProximityMineComponent(position: Vector2(800, 800));
          final farPlayer = Vector2(2000, 2000);
          final nearbyEnemy = EnemyShipComponent(
            position: Vector2(880, 800), // Inside 155px triggerRadius
            type: EnemyType.raider,
          );

          expect(mine.isArmed, isFalse);
          expect(mine.isDetonated, isFalse);

          // Advance 0.5s with player far away and enemy inside trigger radius -> arms
          final detonatedOnApproach = mine.evaluateProximityTriggers(
            0.50,
            playerPos: farPlayer,
            playerRadius: 15.0,
            enemies: [nearbyEnemy],
          );
          expect(mine.isArmed, isTrue);
          expect(detonatedOnApproach, isFalse);

          // Move enemy to contact range -> mine detonates bi-directionally
          nearbyEnemy.position = Vector2(820, 800);
          final detonatedOnContact = mine.evaluateProximityTriggers(
            0.05,
            playerPos: farPlayer,
            playerRadius: 15.0,
            enemies: [nearbyEnemy],
          );
          expect(detonatedOnContact, isTrue);
          expect(mine.isDetonated, isTrue);
        },
      );

      test(
        'Dash-ramming an Asteroid launches it cleanly and crushes heavy enemies on impact',
        () {
          final game = AsteroidsGame()..state = GameState.playing;
          final player = PlayerComponent(position: Vector2(400, 400))
            ..customGame = game
            ..dashActiveTimer = 0.25; // Active Dash
          final initialHp = player.hp;

          final asteroid = AsteroidComponent(
            radius: 36.0,
            position: Vector2(440, 400),
            velocity: Vector2(10, 0),
          );

          // Dash collision launches asteroid along +X and deals ZERO damage to player
          player.onCollisionStart({asteroid.position.clone()}, asteroid);
          expect(player.hp, initialHp);
          expect(asteroid.launchedByDashTimer, greaterThan(1.0));
          expect(asteroid.velocity.x, greaterThan(450.0));
          expect(asteroid.isKineticHazard, isTrue);

          // Kinetic asteroid strikes an AegisBulwark from behind
          final bulwark = EnemyShipComponent(
            position: Vector2(475, 400),
            type: EnemyType.aegisBulwark,
          )..angle = 0.0; // Facing -Y, so hit from -X is unshielded
          final startBulwarkHp = bulwark.hp;

          bulwark.resolveAsteroidImpact(asteroid);

          expect(bulwark.hp, lessThan(startBulwarkHp - 100.0));
          expect(bulwark.kineticHitCooldown, greaterThan(0.0));
          expect(
            asteroid.velocity.length,
            lessThan(450.0),
          ); // Kinetic dampening
        },
      );

      test(
        'Zero-GC Smoke Test: Telegraphed Sniper and Dreadnought render cleanly in both amber and crimson phases',
        () {
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);

          final sniper =
              EnemyShipComponent(
                  position: Vector2(300, 300),
                  type: EnemyType.sniper,
                )
                ..isTelegraphingShot = true
                ..shotTelegraphTimer = 0.50; // Amber tracking window
          sniper.render(canvas);

          sniper.shotTelegraphTimer = 0.10; // Crimson aim-locked window
          sniper.render(canvas);

          final leviathan =
              DreadnoughtLeviathanComponent(position: Vector2(600, 600))
                ..isTelegraphingBeam = true
                ..beamTelegraphDuration = 0.15;
          leviathan.render(canvas);

          final pic = recorder.endRecording();
          expect(pic, isNotNull);
          pic.dispose();
        },
      );
    },
  );
}
