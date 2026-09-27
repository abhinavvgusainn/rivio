import 'dart:async';

import 'package:flutter/services.dart';

class InteractionFeedback {
  static bool enabled = true;

  static void tap() {
    if (!enabled) return;
    unawaited(SystemSound.play(SystemSoundType.click).catchError((_) {}));
    unawaited(HapticFeedback.selectionClick().catchError((_) {}));
  }

  static void celebrate({bool sound = true}) {
    if (!enabled) return;
    if (sound) {
      unawaited(SystemSound.play(SystemSoundType.alert).catchError((_) {}));
    }
    unawaited(HapticFeedback.mediumImpact().catchError((_) {}));
  }
}
