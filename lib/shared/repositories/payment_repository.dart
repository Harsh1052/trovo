import '../../config/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../services/purchase_service.dart';

// ── Abstract contract ─────────────────────────────────────────────────────────

abstract class PaymentRepository {
  Future<Result<bool>> get hasPremiumEntitlement;
  Future<Result<bool>> hasHuntAccess(String huntId);
  Future<Result<void>> purchaseHunt(String productId);
  Future<Result<void>> purchasePremium(String productId);
  Future<Result<void>> restorePurchases();
}

// ── RevenueCat implementation ─────────────────────────────────────────────────

class RevenueCatPaymentRepository implements PaymentRepository {
  RevenueCatPaymentRepository({required PurchaseService purchaseService})
      : _purchaseService = purchaseService;

  final PurchaseService _purchaseService;

  @override
  Future<Result<bool>> get hasPremiumEntitlement async {
    try {
      final has = await _purchaseService
          .hasEntitlement(AppConstants.rcEntitlementPremium);
      return Success(has);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(UnknownFailure('$e'));
    }
  }

  @override
  Future<Result<bool>> hasHuntAccess(String huntId) async {
    try {
      final has = await _purchaseService.hasEntitlement(huntId);
      return Success(has);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return const Success(false);
    }
  }

  @override
  Future<Result<void>> purchaseHunt(String productId) async {
    try {
      await _purchaseService.purchaseProduct(productId);
      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(PaymentException('Purchase failed: $e').toFailure());
    }
  }

  @override
  Future<Result<void>> purchasePremium(String productId) async {
    try {
      await _purchaseService.purchaseProduct(productId);
      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(PaymentException('Premium purchase failed: $e').toFailure());
    }
  }

  @override
  Future<Result<void>> restorePurchases() async {
    try {
      await _purchaseService.restorePurchases();
      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(PaymentException('Restore failed: $e').toFailure());
    }
  }
}
