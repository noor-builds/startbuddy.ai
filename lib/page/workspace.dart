import 'package:flutter/material.dart';
import 'package:startbuddy/models/startup.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key, required this.startup});

  final Startup startup;

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(children: [Text('Workspace')]),
        ),
      ),
    );
  }
}
