/// Global formatting utilities used across the app.

const _monthNames = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Format a DateTime to relative "time ago" string.
/// Examples: "now", "5m", "2h", "3d", "25-Dec-2024"
String formatTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}-${_monthNames[dt.month]}-${dt.year}';
}

/// Shorten a pubkey to first 8 characters + ellipsis.
String formatShortPubkey(String pubkey) {
  if (pubkey.length <= 12) return pubkey;
  return '${pubkey.substring(0, 8)}…';
}

/// Truncate content to 80 chars with ellipsis if needed.
String formatContentPreview(String content) =>
    content.length > 80 ? '${content.substring(0, 80)}…' : content;
