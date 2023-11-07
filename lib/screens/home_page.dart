import 'package:flutter/material.dart';
import 'package:move_tracker/screens/log.dart';
import 'package:move_tracker/screens/logbook.dart';
import 'package:move_tracker/screens/settings.dart';

class HomePageScreen extends StatelessWidget {
  const HomePageScreen(this.title, {super.key});

  final String title;

  void _moveToSettings(BuildContext ctx) => Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );

  void _moveToLog(BuildContext ctx) => Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (context) => const LogScreen(),
        ),
      );

  void _moveToLogbook(BuildContext ctx) => Navigator.of(ctx)
      .push(MaterialPageRoute(builder: (context) => const LogbookScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _moveToSettings(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Diario'),
              onPressed: () => _moveToLogbook(context),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              child: const Text('Log'),
              onPressed: () {
                return _moveToLog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
