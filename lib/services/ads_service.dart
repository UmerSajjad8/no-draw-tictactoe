import 'package:flutter/foundation.dart';

// Ads temporarily disabled to rule out AdMob crashes on device.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  String get bannerUnitId => '';
  String get rewardedUnitId => '';

  Future<void> init() async {}

  Future<void> showRewarded({required VoidCallback onReward}) async {
    // No ad — just grant the reward so Hint/Undo still work.
    onReward();
  }
}