import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class InteractionFeedback {
  static bool enabled = true;
  static AudioPlayer? _player;
  static Future<AudioPlayer>? _ready;
  static int _playbackRequest = 0;

  static Future<void> initialize() async {
    try {
      await _getPlayer();
    } catch (_) {}
  }

  static Future<AudioPlayer> _getPlayer() async {
    final player = _player ??= AudioPlayer();
    final ready = _ready ??= _configurePlayer(player);
    await ready;
    return player;
  }

  static Future<AudioPlayer> _configurePlayer(AudioPlayer player) async {
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(1.0);
    return player;
  }

  static void setEnabled(bool value) {
    enabled = value;
    if (!value) stopSound();
  }

  static void tap() {
    if (!enabled) return;
    unawaited(HapticFeedback.selectionClick().catchError((_) {}));
  }

  static void flip() {
    if (!enabled) return;
    unawaited(_play('flip.mp3'));
    unawaited(HapticFeedback.selectionClick().catchError((_) {}));
  }

  static void cardCreated() {
    if (!enabled) return;
    unawaited(_play('flip.mp3'));
    unawaited(HapticFeedback.selectionClick().catchError((_) {}));
  }

  static void celebrate({bool sound = true}) {
    if (!enabled) return;
    if (sound) playBell();
    unawaited(HapticFeedback.mediumImpact().catchError((_) {}));
  }

  static void playBell() {
    if (!enabled) return;
    unawaited(_play('bell.mp3'));
  }

  static void deckCompleted() {
    if (!enabled) return;
    unawaited(_play('achievement.mp3'));
    unawaited(HapticFeedback.mediumImpact().catchError((_) {}));
  }

  static Future<void> _play(String fileName) async {
    if (!enabled) return;
    final request = ++_playbackRequest;
    try {
      final player = await _getPlayer();
      if (!enabled || request != _playbackRequest) return;
      await player.stop();
      if (!enabled || request != _playbackRequest) return;
      await player.play(AssetSource('sounds/$fileName'));
    } catch (_) {}
  }

  static void stopSound() {
    _playbackRequest++;
    final player = _player;
    if (player != null) unawaited(player.stop().catchError((_) {}));
  }
}
