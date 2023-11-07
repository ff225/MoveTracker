import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/data/models/logbook_entry.dart';

final logbookProvider = FutureProvider<List<LogbookEntry>>((ref) async {
  return await DatabaseMoveTracker.instance.getAllLogbookEntry();
});
