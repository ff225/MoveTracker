import 'package:flutter/material.dart';
import 'package:move_tracker/screens/log.dart';
import 'package:move_tracker/screens/settings.dart';
import 'package:move_tracker/services/accelerometer_service.dart';
import 'package:workmanager/workmanager.dart';

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
              onPressed: () async {
                Workmanager()
                    .registerOneOffTask('readMovesense', 'read-from-movesense');
                if (await AccelerometerService().service.isRunning()) {
                  print('send-value in Diario');

                  Workmanager().registerOneOffTask('showData', 'send-value');
                } else {
                  AccelerometerService().service.startService();
                }
              },
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
