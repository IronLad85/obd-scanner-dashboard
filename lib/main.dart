import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'stores/obd_store.dart';
import 'pages/connection_page.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OBD Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ObdDashboard(),
    );
  }
}

class ObdDashboard extends StatefulWidget {
  const ObdDashboard({super.key});

  @override
  State<ObdDashboard> createState() => _ObdDashboardState();
}

class _ObdDashboardState extends State<ObdDashboard> {
  final ObdStore _store = ObdStore();

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        // Navigate to DashboardPage when connected, ConnectionPage when disconnected
        if (_store.isConnected) {
          return DashboardPage(store: _store);
        } else {
          return ConnectionPage(store: _store);
        }
      },
    );
  }
}
