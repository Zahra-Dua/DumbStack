class Validators {
  static String? validateEmail(String? v) {
    if (v == null || !v.contains('@')) return 'Enter valid email';
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.length < 6) return 'Minimum 6 characters';
    return null;
  }
}
