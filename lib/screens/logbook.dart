import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/providers/logbook_notifier.dart';

import 'new_logbook_entry.dart';

class LogbookScreen extends ConsumerStatefulWidget {
  const LogbookScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _LogbookScreenState();
  }
}

class _LogbookScreenState extends ConsumerState<LogbookScreen> {
  void _moveToNewEntry(BuildContext ctx) => Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (context) => const NewLogbookEntry(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(logbookProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario'),
      ),
      body: entries.when(
        data: (data) {
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return Dismissible(
                  direction: DismissDirection.endToStart,
                  key: Key(data[index].timestamp.toIso8601String()),
                  background: Container(color: Colors.red),
                  onDismissed: (direction) {
                    setState(() {
                      DatabaseMoveTracker.instance
                          .removeLogbookEntry(data[index]);
                      data.removeAt(index);
                    });
                  },
                  child: ListTile(
                    title: Text(data[index].title),
                    subtitle: Text(data[index].note),
                  ));
            },
          );
        },
        error: (error, stackTrace) {
          return const Center(
            child: Text('Impossibile caricare il diario.\nRiprova più tardi'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _moveToNewEntry(context),
      ),
    );
  }
}
