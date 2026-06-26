import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  RewardedAd? _rewardedAd;

  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBanneriOS =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardediOS =
      'ca-app-pub-3940256099942544/1712485313';

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  String get bannerUnitId {
    return _isAndroid ? _testBannerAndroid : _testBanneriOS;
  }

  String get rewardedUnitId {
    return _isAndroid ? _testRewardedAndroid : _testRewardediOS;
  }

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadRewarded();
    } catch (e) {
      debugPrint('AdMob init failed (continuing without ads): $e');
    }
  }

  BannerAd createBanner() {
    return BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner failed: $err');
          ad.dispose();
        },
      ),
    );
  }

  void _loadRewarded() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded failed: $err');
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<void> showRewarded({required VoidCallback onReward}) async {
    if (kIsWeb) {
      onReward();
      return;
    }
    final ad = _rewardedAd;
    if (ad == null) {
      onReward();
      _loadRewarded();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
        onReward();
      },
    );
    var rewarded = false;
    await ad.show(onUserEarnedReward: (_, __) => rewarded = true);
    if (rewarded) onReward();
  }
}
