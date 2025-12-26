import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoaded = false;

  // ✅ OFFICIAL TEST AD UNIT IDS (Google provided)
  static const String _androidTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _iosTestAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  /// Load rewarded ad (Android / iOS only)
  void loadAd() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return; // ❌ Skip on Windows/Web
    }

    RewardedAd.load(
      adUnitId:
          Platform.isAndroid ? _androidTestAdUnitId : _iosTestAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isLoaded = false;
        },
      ),
    );
  }

  /// Show rewarded ad
  Future<bool> showAd() async {
    if (!_isLoaded || _rewardedAd == null) {
      return false;
    }

    bool rewardEarned = false;

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) {
        rewardEarned = true;
      },
    );

    _rewardedAd = null;
    _isLoaded = false;

    // Preload next ad
    loadAd();

    return rewardEarned;
  }
}
