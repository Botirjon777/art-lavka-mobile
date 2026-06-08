import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/foundation.dart';

/// Studio session: the signed-in user + their designer profile. The router's
/// KYC gate reads [isVerified] (SPEC §9 — no dashboard until verified).
class AppSession extends ChangeNotifier {
  AppUser? _user;
  DesignerProfile? _profile;

  AppUser? get user => _user;
  DesignerProfile? get profile => _profile;

  bool get isSignedIn => _user != null;

  /// Onboarding submitted (profile exists and not rejected).
  bool get hasOnboarded =>
      _profile != null && _profile!.kycStatus != KycStatus.rejected;

  bool get isVerified => _profile?.kycStatus == KycStatus.verified;

  void setUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void setProfile(DesignerProfile? profile) {
    _profile = profile;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _profile = null;
    notifyListeners();
  }
}
