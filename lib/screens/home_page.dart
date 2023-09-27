import 'package:flutter/material.dart';
import 'package:move_tracker/screens/settings.dart';

class HomePageScreen extends StatelessWidget {
  const HomePageScreen(this.title, {super.key});

  final String title;

  void _moveToSettings(BuildContext ctx) => Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (context) => SettingsScreen(),
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
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(
            onPressed: () {},
            child: Text('Diario'),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text('Log'),
          ),
        ]),
      ),
    );
  }
}
