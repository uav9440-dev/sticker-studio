import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product ID for the one-time lifetime unlock. Create a non-consumable
/// in-app product with this exact ID in Google Play Console — the PRICE is
/// set there (and can be changed any time without updating the app).
const kProProductId = 'pro_lifetime';

/// Trial length: 3 days from first launch.
const kTrialLength = Duration(days: 3);

class EntitlementState {
  const EntitlementState({
    required this.isPro,
    required this.trialEndsAt,
    this.products = const [],
    this.loading = true,
  });

  final bool isPro;
  final DateTime? trialEndsAt;
  final List<ProductDetails> products;
  final bool loading;

  bool get inTrial =>
      trialEndsAt != null && DateTime.now().isBefore(trialEndsAt!);

  /// Master gate used across the app: premium features work while the user
  /// is Pro OR still inside the trial window.
  bool get isActive => isPro || inTrial;

  Duration get trialRemaining => trialEndsAt == null
      ? Duration.zero
      : trialEndsAt!.difference(DateTime.now());

  EntitlementState copyWith({
    bool? isPro,
    DateTime? trialEndsAt,
    List<ProductDetails>? products,
    bool? loading,
  }) =>
      EntitlementState(
        isPro: isPro ?? this.isPro,
        trialEndsAt: trialEndsAt ?? this.trialEndsAt,
        products: products ?? this.products,
        loading: loading ?? this.loading,
      );
}

final entitlementProvider =
    NotifierProvider<EntitlementController, EntitlementState>(
        EntitlementController.new);

/// Purchase + trial state.
///
/// Security model, honestly stated:
///  * The purchase itself is verified by GOOGLE PLAY BILLING — the store is
///    the source of truth, and `restorePurchases` re-verifies on reinstall.
///    This is the strong part: pirating the unlock requires defeating Play,
///    not this app.
///  * The 3-day trial start is stored on-device. A determined user can reset
///    it by reinstalling; the upgrade path (Milestone 5) is anchoring the
///    trial server-side or via Play account signals. For launch, on-device
///    is the standard pragmatic choice.
class EntitlementController extends Notifier<EntitlementState> {
  static const _kTrialStartKey = 'trial_started_at';
  static const _kProCacheKey = 'pro_cached'; // offline grace only

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  EntitlementState build() {
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(_onPurchases);
    ref.onDispose(() => _sub?.cancel());
    _init();
    return const EntitlementState(isPro: false, trialEndsAt: null);
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // Start the trial clock on very first launch.
    var startMs = prefs.getInt(_kTrialStartKey);
    if (startMs == null) {
      startMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_kTrialStartKey, startMs);
    }
    final trialEndsAt =
        DateTime.fromMillisecondsSinceEpoch(startMs).add(kTrialLength);

    // Cached Pro flag gives offline users their unlock immediately;
    // Play restore below remains the authority.
    final cachedPro = prefs.getBool(_kProCacheKey) ?? false;

    List<ProductDetails> products = const [];
    if (await _iap.isAvailable()) {
      final resp = await _iap.queryProductDetails({kProProductId});
      products = resp.productDetails;
      // Ask Play for owned purchases → fires _onPurchases with restored items.
      await _iap.restorePurchases();
    }

    state = EntitlementState(
      isPro: cachedPro,
      trialEndsAt: trialEndsAt,
      products: products,
      loading: false,
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != kProProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_kProCacheKey, true);
          state = state.copyWith(isPro: true);
        case PurchaseStatus.error || PurchaseStatus.canceled:
          break;
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  /// Launch the Google Play purchase sheet for the lifetime unlock.
  Future<void> buyPro() async {
    final product = state.products
        .where((p) => p.id == kProProductId)
        .toList();
    if (product.isEmpty) return;
    await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product.first));
  }

  Future<void> restore() => _iap.restorePurchases();
}
