import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugLocationService extends StatefulWidget {
  const DebugLocationService({Key? key}) : super(key: key);

  @override
  _DebugLocationServiceState createState() => _DebugLocationServiceState();
}

class _DebugLocationServiceState extends State<DebugLocationService> {
  static const platform = MethodChannel('com.alertcontacts.alertcontacts/location');

  @override
  void initState() {
    super.initState();
    _startService();
  }

  Future<void> _startService() async {
    try {
      await platform.invokeMethod('startLocationService');
    } on PlatformException catch (e) {
      print("Failed to start service: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Location Service'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Start Location Service'),
              onPressed: () async {
                try {
                  await platform.invokeMethod('startLocationService');
                } on PlatformException catch (e) {
                  print("Failed to start service: '${e.message}'.");
                }
              },
            ),
            ElevatedButton(
              child: const Text('Stop Location Service'),
              onPressed: () async {
                try {
                  await platform.invokeMethod('stopLocationService');
                } on PlatformException catch (e) {
                  print("Failed to stop service: '${e.message}'.");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}