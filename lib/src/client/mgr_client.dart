import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/mgr5_core.dart';
import 'package:flutter_mgr5/src/client/auth_info.dart';
import 'package:flutter_mgr5/src/mgr_model.dart';

abstract class MgrClient implements Listenable, ChangeNotifier {
  AuthInfo? get authInfo;

  bool get isValid;

  @protected
  bool get isInvalidated;

  Future<bool> validate();

  Future<void> request(MgrRequest request);

  Future<MgrModel> requestModel(MgrRequest request);

  @protected
  void invalidate();

  @protected
  void invalidateIfNeeded(MgrException exception);
}

abstract class MgrClientMixin implements MgrClient {
  bool _isInvalidated = false;

  @override
  bool get isValid => // web can authenticate thru cookies
      !isInvalidated && (kIsWeb || (authInfo?.isValid ?? false));

  @override
  @protected
  bool get isInvalidated => _isInvalidated;

  @override
  Future<bool> validate() async {
    if (!isValid) return false;

    try {
      await request(MgrRequest.func('whoami'));
    } catch (_) {}

    return isValid;
  }

  @override
  @protected
  void invalidate() {
    if (!_isInvalidated) {
      _isInvalidated = true;
      notifyListeners();
    }
  }

  @override
  @protected
  void invalidateIfNeeded(MgrException exception) {
    if (exception.type == 'auth') invalidate();
  }
}
