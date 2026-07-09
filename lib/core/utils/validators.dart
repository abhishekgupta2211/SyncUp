/// Form validators for auth & onboarding.
class Validators {
  Validators._();

  static final _emailRe = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
  static final _usernameRe = RegExp(r'^[a-z0-9_]{3,30}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRe.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name is too short';
    if (v.length > 50) return 'Name is too long';
    return null;
  }

  /// Username must be lowercase a–z, 0–9 or underscore, 3–30 chars.
  static String? username(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.isEmpty) return 'Username is required';
    if (v.length < 3) return 'At least 3 characters';
    if (v.length > 30) return 'At most 30 characters';
    if (!_usernameRe.hasMatch(v)) {
      return 'Only a–z, 0–9 and _ allowed';
    }
    // Reserved: the auto-generated placeholder shape (user_<8 hex>).
    if (RegExp(r'^user_[0-9a-f]{8}$').hasMatch(v)) {
      return 'Please choose a different username';
    }
    return null;
  }
}
