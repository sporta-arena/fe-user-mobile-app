// Utility class for timezone conversions
// Server uses UTC, frontend displays in local time (WIB = UTC+7)

class TimezoneUtils {
  /// Convert UTC DateTime from server to local time for display
  static DateTime utcToLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Convert local DateTime to UTC for sending to server
  static DateTime localToUtc(DateTime localDateTime) {
    return localDateTime.toUtc();
  }

  /// Parse UTC datetime string from server and convert to local
  static DateTime parseUtcToLocal(String utcString) {
    // If string doesn't have timezone info, assume it's UTC
    DateTime parsed;
    if (utcString.endsWith('Z') || utcString.contains('+') || utcString.contains('-', 10)) {
      parsed = DateTime.parse(utcString);
    } else {
      // Append 'Z' to indicate UTC if no timezone info
      parsed = DateTime.parse('${utcString}Z');
    }
    return parsed.toLocal();
  }

  /// Format local DateTime to UTC ISO string for server
  static String formatToUtcString(DateTime localDateTime) {
    return localDateTime.toUtc().toIso8601String();
  }

  /// Parse date string (YYYY-MM-DD) - dates don't need timezone conversion
  static DateTime parseDate(String dateString) {
    return DateTime.parse(dateString.split('T')[0]);
  }

  /// Format date to YYYY-MM-DD string for server
  static String formatDateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if a UTC datetime has expired (comparing with current UTC time)
  static bool isExpired(DateTime utcExpiry) {
    return DateTime.now().toUtc().isAfter(utcExpiry);
  }

  /// Get remaining duration from now until UTC expiry
  static Duration getRemainingTime(DateTime utcExpiry) {
    return utcExpiry.difference(DateTime.now().toUtc());
  }

  /// Convert time string (HH:mm:ss or HH:mm) to display format
  /// Note: Time slots are in venue's local time, no conversion needed
  static String formatTimeDisplay(String timeString) {
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeString;
  }
}
