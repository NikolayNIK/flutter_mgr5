import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';

abstract class MgrExceptionHolder {
  factory MgrExceptionHolder([MgrException? exception]) =>
      _RootMgrExceptionHolder(exception);

  MgrException? peek();

  MgrException? consume();

  MgrExceptionHolder? createHolderForField(String fieldName) =>
      _FieldMgrExceptionHolder(this, fieldName);

  MgrExceptionHolder createHolderWithCallback(VoidCallback callback) =>
      _CallbackExceptionHolder(this, callback: callback);
}

class _RootMgrExceptionHolder with MgrExceptionHolder {
  MgrException? _exception;

  _RootMgrExceptionHolder(this._exception);

  @override
  MgrException? peek() => _exception;

  @override
  MgrException? consume() {
    final e = _exception;
    _exception = null;
    return e;
  }

  @override
  MgrExceptionHolder? createHolderForField(String fieldName) =>
      _exception == null ? null : _FieldMgrExceptionHolder(this, fieldName);
}

class _FieldMgrExceptionHolder with MgrExceptionHolder {
  final MgrExceptionHolder _holder;
  final String _fieldName;

  _FieldMgrExceptionHolder(this._holder, this._fieldName);

  @override
  MgrException? consume() {
    final exception = _holder.peek();
    if (exception?.object == _fieldName) {
      return _holder.consume();
    }

    return null;
  }

  @override
  MgrException? peek() => _holder.peek();
}

class _CallbackExceptionHolder with MgrExceptionHolder {
  final MgrExceptionHolder _holder;
  final VoidCallback? callback;

  _CallbackExceptionHolder(this._holder, {this.callback});

  @override
  MgrException? consume() {
    callback?.call();
    return _holder.consume();
  }

  @override
  MgrException? peek() => _holder.peek();
}
