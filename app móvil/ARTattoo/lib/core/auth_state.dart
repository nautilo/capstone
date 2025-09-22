import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier implements ValueListenable<AuthState> {
  String? token;
  String? role; // 'client'|'artist'
  String? name;
  int? userId;

  bool get isLoggedIn => token != null;

  void set({required String token, required String role, required String name, required int userId}) {
    this.token = token; this.role = role; this.name = name; this.userId = userId;
    notifyListeners();
  }

  void clear() { token=null; role=null; name=null; userId=null; notifyListeners(); }

  @override
  AuthState get value => this;
}

final authState = AuthState();
