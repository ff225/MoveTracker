class LogbookEntry {
  final DateTime timestamp;
  final String title;
  final String note;
  final int isSent;

  LogbookEntry(this.timestamp, this.title, this.note, {this.isSent = 0});

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'note': note,
      'is_sent': isSent
    };
  }
}
