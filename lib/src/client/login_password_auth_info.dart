import 'package:flutter_mgr5/src/client/auth_info.dart';

class LoginPasswordAuthInfo extends AuthInfo {
  final String login, password;

  LoginPasswordAuthInfo(this.login, this.password, super.lang);

  @override
  void intoParams(Map<String, String> params) {
    super.intoParams(params);
    params['authinfo'] = '$login:$password';
  }

  @override
  bool get isValid => login.isNotEmpty && password.isNotEmpty;
}