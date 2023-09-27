import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _string = 'Settings';

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              trailing: IconButton(
                onPressed: () {
                  setState(() {
                    _string = 'pressed';
                  });
                },
                icon: const Icon(Icons.refresh),
              ),
            ),
            child: Center(
              child: Text(
                _string,
                style: const CupertinoTextThemeData()
                    .textStyle
                    .copyWith(fontSize: 100),
              ),
            ))
        : Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _string = 'pressed';
                    });
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: Center(
              child: Text(_string),
            ),
          );
  }
}
