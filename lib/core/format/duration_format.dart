String formatDuration(Duration duration) {
  if (duration.inDays > 0) {
    final hours = duration.inHours % 24;
    return '${duration.inDays}d ${hours}h';
  }
  if (duration.inHours > 0) {
    final minutes = duration.inMinutes % 60;
    return '${duration.inHours}h ${minutes}m';
  }
  if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m';
  }
  return '${duration.inSeconds}s';
}
