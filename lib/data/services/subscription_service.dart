import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'backend_service.dart';
import '../../core/constants.dart';

class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false;
  String _plan = 'free';
  DateTime? _expiresAt;

  bool get available => _available;
  String get plan => _plan;
  DateTime? get expiresAt => _expiresAt;
  bool get isPro => _plan != 'free';

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (_available) {
      _subscription = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
      await refresh();
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!BackendService.instance.authenticated) return;
    try {
      final result = await BackendService.instance.get('/billing/status');
      _plan = result['plan']?.toString() ?? 'free';
      final raw = result['expiresAt']?.toString();
      _expiresAt = raw == null ? null : DateTime.tryParse(raw);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> buy(String productId) async {
    if (!_available) throw StateError('متجر الاشتراكات غير متاح على هذا الجهاز.');
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) throw StateError('الاشتراك غير مضاف في المتجر بعد.');
    final purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) throw StateError('تعذر بدء عملية الاشتراك.');
  }

  Future<void> buyMonthly() => buy(AppConstants.monthlyProductId);
  Future<void> buyQuarterly() => buy(AppConstants.quarterlyProductId);
  Future<void> buyYearly() => buy(AppConstants.yearlyProductId);

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        try {
          await BackendService.instance.post('/billing/verify', {
            'productId': purchase.productID,
            'purchaseId': purchase.purchaseID,
            'verificationData': purchase.verificationData.serverVerificationData,
            'source': purchase.verificationData.source,
          });
          await refresh();
        } catch (_) {}
      }
      if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
