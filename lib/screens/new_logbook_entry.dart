import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/data/models/logbook_entry.dart';
import 'package:move_tracker/providers/logbook_notifier.dart';

class NewLogbookEntry extends ConsumerStatefulWidget {
  const NewLogbookEntry({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _NewLogbookEntryState();
  }
}

class _NewLogbookEntryState extends ConsumerState<NewLogbookEntry> {
  final _formKey = GlobalKey<FormState>();
  late String? _title;
  late String? _note;

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      log("title: $_title");
      log('note: $_note');
      DatabaseMoveTracker.instance.insertLogbookEntry(
        LogbookEntry(DateTime.timestamp().toUtc(), _title!, _note!),
      );
      Navigator.of(context).pop(ref.refresh(logbookProvider));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Com'è andata la giornata?"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Titolo',
                    icon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1 ||
                        value.trim().length > 50) {
                      return 'Il titolo non può essere vuoto!';
                    }
                    return null;
                  },
                  onSaved: (newTitle) {
                    _title = newTitle;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  maxLength: 100,
                  decoration: const InputDecoration(
                      icon: Icon(Icons.notes),
                      labelText: "Scrivi un breve riassunto della giornata"),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1 ||
                        value.trim().length > 100) {
                      return 'Il campo non può essere vuoto!';
                    }
                    return null;
                  },
                  onSaved: (newNote) {
                    _note = newNote;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _formKey.currentState!.reset();
                      },
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: _saveItem,
                      child: const Text('Aggiungi'),
                    )
                  ],
                )
              ],
            )),
      ),
    );
  }
}
