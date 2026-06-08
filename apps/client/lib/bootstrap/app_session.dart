import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/foundation.dart';

/// App-wide auth session. A plain [ChangeNotifier] so the router can use it as a
/// `refreshListenable` and screens can rebuild on sign-in/out.
///
/// The auth controller is the only writer; the router reads it in `redirect`.
class AppSession extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  /// First-login gate: a profile is complete once a display name exists (SPEC §8).
  bool get hasProfile => (_user?.fullName ?? '').trim().isNotEmpty;

  void setUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
