// Fungsi murni untuk format tanggal dan parsing rute.
// Berada di core tanpa dependensi framework Flutter/Widget.

String formatDisplayDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

int parseRouteId(String? idStr) {
  if (idStr == null || idStr.trim().isEmpty) return 0;
  return int.tryParse(idStr.trim()) ?? 0;
}

String formatNoteSnippet({
  required String body,
  int maxLength = 60,
}) {
  final clean = body.replaceAll('\n', ' ').trim();
  if (clean.isEmpty) return 'Tidak ada isi tambahan';
  if (clean.length <= maxLength) return clean;
  return '${clean.substring(0, maxLength)}...';
}
