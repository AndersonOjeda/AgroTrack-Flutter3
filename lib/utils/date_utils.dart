class DateUtilsAgro {
  // Parse input in dd/MM/yyyy to DateTime (local)
  static DateTime? parseBirthDate(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final s = input.trim();
    // Try dd/MM/yyyy
    final parts = s.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {
          // Fall through to ISO parsing
        }
      }
    }
    // Fallback to ISO 8601 parsing
    return DateTime.tryParse(s);
  }

  // Format DateTime to dd/MM/yyyy
  static String? formatBirthDate(DateTime? date) {
    if (date == null) return null;
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }
}