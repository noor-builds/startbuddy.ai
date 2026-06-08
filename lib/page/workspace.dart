import 'package:flutter/material.dart';
import 'package:startbuddy/models/startup.dart';
import 'package:startbuddy/service/db/db_service.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key, required this.startupId});

  final int startupId;

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  Startup? _startup;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStartup();
  }

  Future<void> _fetchStartup() async {
    try {
      final data = await DbService().fetchStartupById(widget.startupId);
      if (!mounted) return;
      setState(() {
        _startup = Startup.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF000000),
                Color(0xFF030A14),
                Color(0xFF0A1A33),
                Color(0xFF0D2247),
              ],
            ),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              _startup!.startupName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
