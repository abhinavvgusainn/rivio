import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'interaction_feedback.dart';

class AdsService with WidgetsBindingObserver {
  AdsService._();

  static final AdsService instance = AdsService._();

  static const _androidAppOpenTestId = 'ca-app-pub-3940256099942544/9257395921';
  static const _iosAppOpenTestId = 'ca-app-pub-3940256099942544/5575463023';
  static const _androidNativeTestId = 'ca-app-pub-3940256099942544/2247696110';
  static const _iosNativeTestId = 'ca-app-pub-3940256099942544/3986624511';
  static const _androidAppOpenId = 'ca-app-pub-5770713859706238/6828053177';
  static const _androidNotesNativeId = 'ca-app-pub-5770713859706238/9734427274';
  static const _androidSubjectNativeId =
      'ca-app-pub-5770713859706238/6338107747';
  static const _androidFlashcardsNativeId =
      'ca-app-pub-5770713859706238/5706543194';
  static const _appOpenFreshness = Duration(hours: 4);

  final ValueNotifier<bool> canRequestAdsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> privacyOptionsRequiredNotifier = ValueNotifier(
    false,
  );

  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadedAt;
  DateTime? _lastAppOpenShownAt;
  DateTime? _backgroundedAt;
  bool _observerAdded = false;
  bool _sdkInitialized = false;
  bool _initializingSdk = false;
  bool _loadingAppOpenAd = false;
  bool _showingAppOpenAd = false;

  bool get _supportedPlatform => Platform.isAndroid || Platform.isIOS;

  Duration get _appOpenCooldown =>
      kReleaseMode ? const Duration(hours: 4) : const Duration(seconds: 30);

  Duration get _minimumBackgroundTime =>
      kReleaseMode ? const Duration(minutes: 10) : const Duration(seconds: 1);

  Future<void> initialize() async {
    if (!_supportedPlatform) return;
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => unawaited(_completeConsentFlow()),
        (_) => unawaited(_refreshConsentAndInitialize()),
      );
    } catch (_) {
      await _refreshConsentAndInitialize();
    }
  }

  Future<void> _completeConsentFlow() async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    } catch (_) {}
    await _refreshConsentAndInitialize();
  }

  Future<void> _refreshConsentAndInitialize() async {
    try {
      final required = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequiredNotifier.value =
          required == PrivacyOptionsRequirementStatus.required;
      final allowed = await ConsentInformation.instance.canRequestAds();
      canRequestAdsNotifier.value = allowed;
      if (allowed) await _initializeAdsSdk();
    } catch (_) {
      canRequestAdsNotifier.value = false;
    }
  }

  Future<void> _initializeAdsSdk() async {
    if (_sdkInitialized || _initializingSdk) return;
    _initializingSdk = true;
    try {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
      _loadAppOpenAd();
    } catch (_) {
      _sdkInitialized = false;
    } finally {
      _initializingSdk = false;
    }
  }

  void _loadAppOpenAd() {
    if (!_sdkInitialized ||
        !canRequestAdsNotifier.value ||
        _loadingAppOpenAd ||
        _appOpenAd != null) {
      return;
    }
    _loadingAppOpenAd = true;
    unawaited(
      AppOpenAd.load(
        adUnitId: _appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _loadingAppOpenAd = false;
            _appOpenAd = ad;
            _appOpenLoadedAt = DateTime.now();
            if (kDebugMode) debugPrint('App-open ad loaded and ready.');
          },
          onAdFailedToLoad: (error) {
            _loadingAppOpenAd = false;
            if (kDebugMode) debugPrint('App-open ad failed to load: $error');
          },
        ),
      ).catchError((_) {
        _loadingAppOpenAd = false;
      }),
    );
  }

  String get _appOpenAdUnitId {
    if (kReleaseMode && Platform.isAndroid) return _androidAppOpenId;
    return Platform.isAndroid ? _androidAppOpenTestId : _iosAppOpenTestId;
  }

  String get notesNativeAdUnitId => _nativeUnitId(_androidNotesNativeId);

  String get subjectNativeAdUnitId => _nativeUnitId(_androidSubjectNativeId);

  String get flashcardsNativeAdUnitId =>
      _nativeUnitId(_androidFlashcardsNativeId);

  String _nativeUnitId(String androidProductionId) {
    if (kReleaseMode && Platform.isAndroid) return androidProductionId;
    return Platform.isAndroid ? _androidNativeTestId : _iosNativeTestId;
  }

  Future<void> showPrivacyOptions() async {
    if (!_supportedPlatform) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
      await _refreshConsentAndInitialize();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _backgroundedAt = DateTime.now();
      InteractionFeedback.stopSound();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null || !canRequestAdsNotifier.value) return;
    if (DateTime.now().difference(backgroundedAt) < _minimumBackgroundTime) {
      return;
    }
    final lastShown = _lastAppOpenShownAt;
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < _appOpenCooldown) {
      return;
    }
    final loadedAt = _appOpenLoadedAt;
    if (loadedAt == null ||
        DateTime.now().difference(loadedAt) >= _appOpenFreshness) {
      _disposeAppOpenAd();
      _loadAppOpenAd();
      return;
    }
    _showAppOpenAd();
  }

  void _showAppOpenAd() {
    final ad = _appOpenAd;
    if (ad == null || _showingAppOpenAd || !canRequestAdsNotifier.value) {
      _loadAppOpenAd();
      return;
    }
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _showingAppOpenAd = true;
    _lastAppOpenShownAt = DateTime.now();
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingAppOpenAd = false;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _showingAppOpenAd = false;
        _lastAppOpenShownAt = null;
        _loadAppOpenAd();
      },
    );
    unawaited(
      ad.show().catchError((_) {
        ad.dispose();
        _showingAppOpenAd = false;
        _lastAppOpenShownAt = null;
        _loadAppOpenAd();
      }),
    );
  }

  void _disposeAppOpenAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenLoadedAt = null;
  }
}

class InlineNativeAd extends StatefulWidget {
  const InlineNativeAd({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  State<InlineNativeAd> createState() => _InlineNativeAdState();
}

class _InlineNativeAdState extends State<InlineNativeAd> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AdsService.instance.canRequestAdsNotifier.addListener(
      _onAdsPermissionChanged,
    );
    if (AdsService.instance.canRequestAdsNotifier.value) _loadAd();
  }

  void _onAdsPermissionChanged() {
    if (AdsService.instance.canRequestAdsNotifier.value) {
      _loadAd();
    } else {
      _ad?.dispose();
      _ad = null;
      if (mounted) {
        setState(() {
          _loaded = false;
          _loading = false;
        });
      }
    }
  }

  void _loadAd() {
    if (_ad != null || !AdsService.instance.canRequestAdsNotifier.value) return;
    if (mounted) setState(() => _loading = true);
    final ad = NativeAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: const Color(0xFFF6F8F6),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF171B19),
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF68736C),
          size: 12,
        ),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFFFFFFF),
          backgroundColor: const Color(0xFF087447),
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted ||
              !AdsService.instance.canRequestAdsNotifier.value ||
              !identical(_ad, loadedAd)) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _loaded = true;
            _loading = false;
          });
        },
        onAdFailedToLoad: (failedAd, _) {
          failedAd.dispose();
          if (identical(_ad, failedAd) && mounted) {
            _ad = null;
            setState(() {
              _loaded = false;
              _loading = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    unawaited(
      ad.load().catchError((_) {
        ad.dispose();
        if (identical(_ad, ad) && mounted) {
          _ad = null;
          setState(() {
            _loaded = false;
            _loading = false;
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    AdsService.instance.canRequestAdsNotifier.removeListener(
      _onAdsPermissionChanged,
    );
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if ((!_loaded || _ad == null) && !_loading) {
      return const SizedBox.shrink();
    }
    return Card(
      color: const Color(0xFFF6F8F6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 5),
              child: Text(
                'Advertisement',
                style: TextStyle(
                  color: Color(0xFF68736C),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: _loaded && _ad != null
                  ? AdWidget(ad: _ad!)
                  : const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
