import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

/// Categorias funcionais de áudio inspiradas em Vampire Survivors e Nova Drift.
enum SoundCategory {
  gunfire,
  impacts,
  actions,
  pickups,
  criticalUi,
}

/// Metadados e regras de concorrência por efeito sonoro.
class SoundProfile {
  final SoundCategory category;
  final double baseVolume;
  final int minIntervalMs;
  final int maxConcurrency;
  final bool pitchJitter;
  final bool arpeggio;
  final bool triggersDucking;

  const SoundProfile({
    required this.category,
    this.baseVolume = 1.0,
    this.minIntervalMs = 60,
    this.maxConcurrency = 2,
    this.pitchJitter = false,
    this.arpeggio = false,
    this.triggersDucking = false,
  });
}

/// Motor de Áudio Avançado para Astra Valkyries.
/// Gerencia canais dedicados, particionamento de vozes, limitação de concorrência,
/// arpejo harmônico de stardust e ducking dinâmico para eliminar cortes bruscos e embolamento sonoro.
class SoundEngine {
  static final Map<String, SoundProfile> profiles = {
    // 1. Canal Gunfire (Vozes dedicadas para disparo de armas)
    'shoot.wav': const SoundProfile(
      category: SoundCategory.gunfire,
      baseVolume: 0.32,
      minIntervalMs: 65,
      maxConcurrency: 3,
      pitchJitter: true,
    ),

    // 2. Canal Impacts & Explosions
    'asteroid_split.wav': const SoundProfile(
      category: SoundCategory.impacts,
      baseVolume: 0.65,
      minIntervalMs: 70,
      maxConcurrency: 2,
    ),
    'bomb_explode.wav': const SoundProfile(
      category: SoundCategory.impacts,
      baseVolume: 1.0,
      minIntervalMs: 80,
      maxConcurrency: 2,
    ),
    'player_hit.wav': const SoundProfile(
      category: SoundCategory.impacts,
      baseVolume: 0.95,
      minIntervalMs: 110,
      maxConcurrency: 1,
    ),

    // 3. Canal Player Actions (Mobilidade e Relíquias)
    'dash.wav': const SoundProfile(
      category: SoundCategory.actions,
      baseVolume: 0.85,
      minIntervalMs: 80,
      maxConcurrency: 2,
    ),
    'katana_slash.wav': const SoundProfile(
      category: SoundCategory.actions,
      baseVolume: 0.90,
      minIntervalMs: 80,
      maxConcurrency: 2,
    ),
    'special.wav': const SoundProfile(
      category: SoundCategory.actions,
      baseVolume: 1.0,
      minIntervalMs: 100,
      maxConcurrency: 2,
    ),
    'ultimate_ready.wav': const SoundProfile(
      category: SoundCategory.actions,
      baseVolume: 1.0,
      minIntervalMs: 250,
      maxConcurrency: 1,
    ),

    // 4. Canal Pickups & Stardust (Economia & Coleta)
    'powerup.wav': const SoundProfile(
      category: SoundCategory.pickups,
      baseVolume: 0.70,
      minIntervalMs: 35,
      maxConcurrency: 2,
      arpeggio: true,
    ),
    'titanium_mine.wav': const SoundProfile(
      category: SoundCategory.pickups,
      baseVolume: 0.85,
      minIntervalMs: 40,
      maxConcurrency: 2,
      arpeggio: true,
    ),
    'purchase.wav': const SoundProfile(
      category: SoundCategory.pickups,
      baseVolume: 0.85,
      minIntervalMs: 60,
      maxConcurrency: 2,
    ),

    // 5. Canal Critical & UI (Eventos de alta prioridade protegidos)
    'boss_spawn.wav': const SoundProfile(
      category: SoundCategory.criticalUi,
      baseVolume: 1.0,
      minIntervalMs: 500,
      maxConcurrency: 1,
      triggersDucking: true,
    ),
    'low_health.wav': const SoundProfile(
      category: SoundCategory.criticalUi,
      baseVolume: 0.90,
      minIntervalMs: 350,
      maxConcurrency: 1,
    ),
    'game_over.wav': const SoundProfile(
      category: SoundCategory.criticalUi,
      baseVolume: 1.0,
      minIntervalMs: 500,
      maxConcurrency: 1,
      triggersDucking: true,
    ),
    'level_up.wav': const SoundProfile(
      category: SoundCategory.criticalUi,
      baseVolume: 1.0,
      minIntervalMs: 300,
      maxConcurrency: 1,
      triggersDucking: true,
    ),
    'chest_open.wav': const SoundProfile(
      category: SoundCategory.criticalUi,
      baseVolume: 0.95,
      minIntervalMs: 200,
      maxConcurrency: 1,
    ),
    'beacon_charge.wav': const SoundProfile(
      category: SoundCategory.criticalUi,
      baseVolume: 0.85,
      minIntervalMs: 100,
      maxConcurrency: 1,
    ),
    'menu_select.wav': const SoundProfile(
      category: SoundCategory.criticalUi,
      baseVolume: 0.75,
      minIntervalMs: 40,
      maxConcurrency: 2,
    ),
  };

  // Pools dedicadas por canal de áudio (13 reprodutores especializados)
  final List<AudioPlayer> _gunfirePlayers = [];
  final List<AudioPlayer> _impactPlayers = [];
  final List<AudioPlayer> _actionPlayers = [];
  final List<AudioPlayer> _pickupPlayers = [];
  final List<AudioPlayer> _criticalUiPlayers = [];

  final List<AudioPlayer> _allPlayers = [];

  int _gunfireIndex = 0;
  int _impactIndex = 0;
  int _actionIndex = 0;
  int _pickupIndex = 0;
  int _criticalUiIndex = 0;

  // Rastreamento de concorrência e intervalos
  final Map<String, int> _lastSoundTimestamp = {};
  final Map<String, List<int>> _activeSoundTimestamps = {};

  // Arpejo harmônico para coleta de Stardust (estilo Vampire Survivors)
  int _arpeggioStep = 0;
  int _lastPickupTimestamp = 0;

  // Dynamic ducking
  int _duckingUntilMs = 0;

  final math.Random _random = math.Random();

  List<AudioPlayer> get allPlayers => _allPlayers;

  void initialize({int gunfireCount = 3, int impactCount = 4, int actionCount = 2, int pickupCount = 2, int criticalCount = 2}) {
    dispose();

    _createChannelPlayers(_gunfirePlayers, gunfireCount);
    _createChannelPlayers(_impactPlayers, impactCount);
    _createChannelPlayers(_actionPlayers, actionCount);
    _createChannelPlayers(_pickupPlayers, pickupCount);
    _createChannelPlayers(_criticalUiPlayers, criticalCount);
  }

  void _createChannelPlayers(List<AudioPlayer> targetList, int count) {
    for (int i = 0; i < count; i++) {
      final p = AudioPlayer();
      p.audioCache.prefix = 'assets/sounds/';
      targetList.add(p);
      _allPlayers.add(p);
    }
  }

  void triggerDucking(int durationMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _duckingUntilMs = math.max(_duckingUntilMs, now + durationMs);
  }

  double get currentDuckingFactor {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < _duckingUntilMs) {
      return 0.55; // Reduz 45% de gunfire/impactos para destacar o evento crítico
    }
    return 1.0;
  }

  /// Toca um efeito sonoro com regras estritas de concorrência, canais dedicados e modulação.
  Future<void> playSfx({
    required String name,
    required double masterVolume,
    required double sfxVolume,
    double? volumeMultiplier,
    double? overridePitch,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final profile = profiles[name] ?? const SoundProfile(category: SoundCategory.impacts);

    // 1. Debounce por som (retrigger mínimo)
    final lastTime = _lastSoundTimestamp[name] ?? 0;
    if (now - lastTime < profile.minIntervalMs) {
      return;
    }

    // 2. Capping de concorrência em janela de 100ms
    final recentTimestamps = _activeSoundTimestamps[name] ?? [];
    recentTimestamps.removeWhere((t) => now - t > 100);
    if (recentTimestamps.length >= profile.maxConcurrency) {
      return;
    }
    recentTimestamps.add(now);
    _activeSoundTimestamps[name] = recentTimestamps;
    _lastSoundTimestamp[name] = now;

    // 3. Ativação de ducking se for evento heroico/crítico
    if (profile.triggersDucking) {
      triggerDucking(850);
    }

    // 4. Seleção da pool de vozes dedicada por canal
    final List<AudioPlayer> pool;
    int channelIdx;

    switch (profile.category) {
      case SoundCategory.gunfire:
        pool = _gunfirePlayers;
        _gunfireIndex = (_gunfireIndex + 1) % (pool.isEmpty ? 1 : pool.length);
        channelIdx = _gunfireIndex;
        break;
      case SoundCategory.impacts:
        pool = _impactPlayers;
        _impactIndex = (_impactIndex + 1) % (pool.isEmpty ? 1 : pool.length);
        channelIdx = _impactIndex;
        break;
      case SoundCategory.actions:
        pool = _actionPlayers;
        _actionIndex = (_actionIndex + 1) % (pool.isEmpty ? 1 : pool.length);
        channelIdx = _actionIndex;
        break;
      case SoundCategory.pickups:
        pool = _pickupPlayers;
        _pickupIndex = (_pickupIndex + 1) % (pool.isEmpty ? 1 : pool.length);
        channelIdx = _pickupIndex;
        break;
      case SoundCategory.criticalUi:
        pool = _criticalUiPlayers;
        _criticalUiIndex = (_criticalUiIndex + 1) % (pool.isEmpty ? 1 : pool.length);
        channelIdx = _criticalUiIndex;
        break;
    }

    if (pool.isEmpty) return;
    final player = pool[channelIdx];

    // 5. Cálculo do volume final ponderado com ducking
    double duckFactor = 1.0;
    if (profile.category == SoundCategory.gunfire || profile.category == SoundCategory.impacts) {
      duckFactor = currentDuckingFactor;
    }

    final effectiveVolume = (profile.baseVolume * (volumeMultiplier ?? 1.0) * sfxVolume * masterVolume * duckFactor)
        .clamp(0.0, 1.0);

    // 6. Cálculo do pitch (jitter sutil ou escada harmônica de arpejo)
    double pitch = overridePitch ?? 1.0;
    if (overridePitch == null) {
      if (profile.pitchJitter) {
        pitch = 0.94 + _random.nextDouble() * 0.12; // ±6% de micro-variação
      } else if (profile.arpeggio) {
        if (now - _lastPickupTimestamp < 650) {
          _arpeggioStep = (_arpeggioStep + 1).clamp(0, 8);
        } else {
          _arpeggioStep = 0;
        }
        _lastPickupTimestamp = now;
        pitch = 1.0 + (_arpeggioStep * 0.05); // Escada melódica suave até +40%
      }
    }

    try {
      player.setPlaybackRate(pitch.clamp(0.5, 2.0));
      await player.play(AssetSource(name), volume: effectiveVolume);
    } catch (_) {}
  }

  void dispose() {
    for (final p in _allPlayers) {
      try {
        p.dispose();
      } catch (_) {}
    }
    _gunfirePlayers.clear();
    _impactPlayers.clear();
    _actionPlayers.clear();
    _pickupPlayers.clear();
    _criticalUiPlayers.clear();
    _allPlayers.clear();
  }
}
