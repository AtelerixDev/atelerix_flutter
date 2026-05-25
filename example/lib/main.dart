import 'package:atelerix/atelerix.dart';
import 'package:flutter/material.dart';

void main() {
 
  Atelerix.init(
    url: "http://api.atelerix.dev",
    apiKey: "API_KEY",
    projectId: "PROJECT_ID",
    builder: () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _userId;
  final bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkUserRegistration();
  }

  Future<void> _checkUserRegistration() async {
    await Atelerix.notifications.init();
    final deviceToken = await Atelerix.notifications.deviceToken;
    setState(() {
      _userId = Atelerix.getUserId();
    });

 

    // Request notification permissions
    final granted = await Atelerix.notifications.requestPermissions();
    print("Permissions granted: $granted");

    print("Device token: $deviceToken");
  }

  final String title = "Atelerix Example";

  @override
  Widget build(BuildContext context) {
    Atelerix.notifications.setOnNotificationReceived((data) {
    });
    Atelerix.notifications.setOnNotificationTapped((data) {
    });
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Registration Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Registered: ${_isRegistered ? "Yes" : "No"}'),
                      const SizedBox(height: 4),
                      Text('User ID: ${_userId ?? "Not available"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  print("User ID: ${Atelerix.getUserId()}");
                },
                child: const Text("Print User ID to Console"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await _checkUserRegistration();
                },
                child: const Text("Check Registration Status"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  try {
                    throw Exception("Test exception");
                  } catch (exception, stack) {
                    Atelerix.throwError(
                      exception,
                      stack,
                      bugSeverity: BugSeverity.high,
                      bugType: BugType.crash,
                    );
                  }
                },
                child: const Text("Throw Test Error"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  try {
                    throw Exception("Test exception with metadata");
                  } catch (exception, stack) {
                    Atelerix.throwError(
                      exception,
                      stack,
                      bugSeverity: BugSeverity.high,
                      bugType: BugType.crash,
                      metaData: {"name": "NASR", "email": "nasr@alqtech.com"},
                    );
                  }
                },
                child: const Text("Throw Error With Metadata"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
