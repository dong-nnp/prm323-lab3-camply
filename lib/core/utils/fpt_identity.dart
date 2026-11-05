abstract final class FptIdentity {
  static String email(String value) => value.trim().toLowerCase();
  static String studentId(String value) => value.trim().toUpperCase();

  static bool validEmail(String value) {
    final normalized = email(value);
    return normalized.length <= 254 &&
        RegExp(
          r"^(?:[A-Za-z0-9_'+\-]+\.)*[A-Za-z0-9_'+\-]*[A-Za-z0-9_+-]@(?:[A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$",
        ).hasMatch(normalized);
  }

  static bool validStudentId(String value) =>
      RegExp(r'^[A-Z]{2}[0-9]{6}$').hasMatch(studentId(value));
}
