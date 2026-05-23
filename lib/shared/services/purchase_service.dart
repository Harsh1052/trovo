import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/error/exceptions.dart';
import '../../core/utils/logger.dart';

class PurchaseService {
  static const _tag = 'PurchaseService';

  // ── Initialisation ───────────────────────────────────────────────────────────

  /// Configure the RevenueCat SDK. Call once from [main] after Firebase is
  /// initialised and before any purchase operations.
  ///
  /// Identical to [configure] but exposed as an instance method so DI can
  /// call it on the registered singleton via a common `init` pattern.
  Future<void> init(String apiKey) => configure(apiKey: apiKey);

  /// Static bootstrap helper used by [initDependencies] before the singleton
  /// is registered.
  static Future<void> configure({required String apiKey}) async {
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(apiKey);
    await Purchases.configure(config);
    AppLogger.i('RevenueCat configured', tag: _tag);
  }

  // ── Offerings ────────────────────────────────────────────────────────────────

  /// Fetch all available RevenueCat offerings.
  ///
  /// Throws [PaymentException] on SDK errors; the repository layer converts
  /// these to [PaymentFailure] via [AppException.toFailure].
  Future<Offerings> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      AppLogger.i(
        'Fetched ${offerings.all.length} offering(s)',
        tag: _tag,
      );
      return offerings;
    } on PurchasesErrorCode catch (e) {
      AppLogger.e('getOfferings failed', tag: _tag, error: e);
      throw PaymentException(e.name);
    } catch (e) {
      AppLogger.e('getOfferings unexpected error', tag: _tag, error: e);
      throw PaymentException('Failed to fetch offerings: $e');
    }
  }

  // ── Purchases ────────────────────────────────────────────────────────────────

  /// Purchase the RevenueCat package whose store product identifier matches
  /// [productId]. Throws [PaymentException] on failure.
  Future<void> purchaseProduct(String productId) async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.all.values
          .expand((o) => o.availablePackages)
          .firstWhere(
            (p) => p.storeProduct.identifier == productId,
            orElse: () => throw PaymentException(
                'Product $productId not found in offerings.'),
          );
      await Purchases.purchasePackage(package);
      AppLogger.i('Purchase completed: $productId', tag: _tag);
    } on PurchasesErrorCode catch (e) {
      AppLogger.e('Purchase error', tag: _tag, error: e);
      throw PaymentException(e.name);
    }
  }

  /// Restore previously completed purchases and update the local entitlement
  /// state. Throws [PaymentException] on failure.
  Future<CustomerInfo> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      AppLogger.i('Purchases restored', tag: _tag);
      return info;
    } on PurchasesErrorCode catch (e) {
      AppLogger.e('Restore error', tag: _tag, error: e);
      throw PaymentException(e.name);
    } catch (e) {
      throw PaymentException('Restore failed: $e');
    }
  }

  // ── Entitlement checks ───────────────────────────────────────────────────────

  /// Returns true if the customer has an active entitlement with
  /// [entitlementId] (e.g. `'premium'`).
  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      AppLogger.e('hasEntitlement failed', tag: _tag, error: e);
      return false;
    }
  }

  /// Convenience wrapper: returns true if the customer has purchased access to
  /// a specific hunt. The RevenueCat entitlement key is `hunt_<huntId>`.
  Future<bool> checkEntitlement(String huntId) =>
      hasEntitlement('hunt_$huntId');

  // ── Identity ─────────────────────────────────────────────────────────────────

  /// Associate the current RevenueCat session with a Firebase/app user ID.
  /// Call after sign-in and after a guest account is upgraded.
  Future<void> identifyUser(String userId) async {
    try {
      await Purchases.logIn(userId);
      AppLogger.i('RevenueCat user identified: $userId', tag: _tag);
    } catch (e) {
      AppLogger.e('identifyUser failed', tag: _tag, error: e);
    }
  }

  /// Detach the current user from RevenueCat. Call on sign-out.
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      AppLogger.e('logOut failed', tag: _tag, error: e);
    }
  }
}
