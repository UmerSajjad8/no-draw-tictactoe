// Lightweight sound + haptic feedback using only Flutter built-ins.
// No audio asset files required.
import 'package:flutter/services.dart';

class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  bool enabled = true;

  void tap() {
    if (!enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  void expand() {
    if (!enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }

  void win() {
    if (!enabled) return;
    // A short double-tick + stronger haptic to feel celebratory.
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 120), () {
      SystemSound.play(SystemSoundType.click);
    });
  }
}
