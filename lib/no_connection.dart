import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'main.dart';

class NoConnectionScreen extends StatefulWidget {
  const NoConnectionScreen({super.key});

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  bool isChecking = false; // To disable button while checking

  Future<void> checkConnection() async {
    setState(() => isChecking = true); // Show loading indicator

    final result = await Connectivity().checkConnectivity();

    if (result.first != ConnectivityResult.none) {
      // If internet is available, refresh app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    } else {
      setState(() => isChecking = false); // Re-enable button if still offline
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 20),
            const Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Please check your internet and try again.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  isChecking ? null : checkConnection, // Disable if checking
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: isChecking
                  ? const CircularProgressIndicator(
                      color: Colors.white) // Show loading
                  : const Text("Try Again",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
