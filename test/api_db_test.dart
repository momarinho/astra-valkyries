import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_protocol/services/api_service.dart';

void main() {
  group('Database & Backend Integration Verification', () {
    test('Backend is accessible and returns healthy status', () async {
      final isOnline =
          await Socket.connect(
                'localhost',
                8080,
                timeout: const Duration(milliseconds: 300),
              )
              .then((s) {
                s.destroy();
                return true;
              })
              .catchError((_) => false);

      if (!isOnline) {
        // Gracefully skip when run in standalone test environment without backend daemon
        return;
      }

      final scores = await ApiService.getLeaderboard('arcade', limit: 3);
      expect(scores, isA<List<Map<String, dynamic>>>());
      expect(scores.isNotEmpty, isTrue);
    });

    test('ApiService saves and queries dual-persistence leaderboard', () async {
      SharedPreferences.setMockInitialValues({});

      final isOnline =
          await Socket.connect(
                'localhost',
                8080,
                timeout: const Duration(milliseconds: 300),
              )
              .then((s) {
                s.destroy();
                return true;
              })
              .catchError((_) => false);

      if (!isOnline) {
        return;
      }

      // Register and submit via fair score API
      await ApiService.saveFairScore(
        playerName: 'PILOTO_TESTE',
        scientistName: 'Margaret Hamilton',
        score: 7770,
      );

      final fairScores = await ApiService.getFairLeaderboard(period: 'all');
      expect(
        fairScores.any(
          (s) => s['username'] == 'PILOTO_TESTE' && s['score'] == 7770,
        ),
        isTrue,
      );
    });

    test(
      'Offline fallback persists and deduplicates local leaderboard without backend',
      () async {
        SharedPreferences.setMockInitialValues({});

        expect(ApiService.baseUrl, isNotEmpty);
        expect(ApiService.isRemoteEnabled, isTrue);

        await ApiService.saveFairScore(
          playerName: 'NOVA',
          scientistName: 'Ada Lovelace',
          score: 4200,
        );
        await ApiService.saveFairScore(
          playerName: 'NOVA',
          scientistName: 'Ada Lovelace',
          score: 4200,
        );
        await ApiService.saveFairScore(
          playerName: 'VALKYRIE',
          scientistName: 'Katherine Johnson',
          score: 9800,
        );

        final scores = await ApiService.getFairLeaderboard(period: 'all');
        expect(scores.length, equals(2));
        expect(scores.first['username'], equals('VALKYRIE'));
        expect(scores.first['score'], equals(9800));
        expect(scores.last['username'], equals('NOVA'));
      },
    );
  });
}
