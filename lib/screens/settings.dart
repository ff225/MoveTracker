import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _iosSettingsUI() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Impostazioni'),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.refresh_outlined),
        ),
      ),
      child: Center(
        child: Text(
          'List...',
          style: const CupertinoTextThemeData().textStyle,
        ),
      ),
    );
  }

  Widget _androidSettingsUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: const Center(
        child: Text('List...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _iosSettingsUI() : _androidSettingsUI();
  }
}
