import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:trusir/no_connection.dart';
import 'main.dart'; // for navigatorKey

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  bool _isDialogShowing = false;

  void initialize() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection =
          results.any((result) => result != ConnectivityResult.none);

      if (!hasConnection && !_isDialogShowing) {
        _isDialogShowing = true;
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const NoConnectionScreen(),
            settings: const RouteSettings(name: '/no-connection'),
          ),
        );
      } else if (hasConnection && _isDialogShowing) {
        navigatorKey.currentState?.popUntil((route) {
          if (route.settings.name == '/no-connection') {
            _isDialogShowing = false;
            return false;
          }
          return true;
        });
      }
    });
  }
}
