import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startbuddy/models/startup.dart';
import 'package:startbuddy/models/document.dart';
import 'package:startbuddy/models/task.dart';
import 'package:startbuddy/service/db/db_service.dart';
import 'package:startbuddy/service/http.dart';
import 'package:startbuddy/theme.dart';

class DashboardView extends StatefulWidget {
  final Startup startup;

  const DashboardView({super.key, required this.startup});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DbService _db = DbService();
  final HttpService _http = HttpService();

  bool _loading = true;
  bool _generatingBlueprint = false;
  String? _error;

  List<StartupTask> _tasks = [];
  List<StartupDocument> _documents = [];
  StartupDocument? _blueprint;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _loading = true);
      final tasksData = await _db.fetchTasksForStartup(widget.startup.id);
      final docsData = await _db.fetchDocumentsForStartup(widget.startup.id);

      if (!mounted) return;

      setState(() {
        _tasks = tasksData.map((t) => StartupTask.fromJson(t)).toList();
        _documents = docsData.map((d) => StartupDocument.fromJson(d)).toList();
        
        // Find blueprint if exists
        final bpIndex = _documents.indexWhere((doc) => doc.type == 'blueprint');
        if (bpIndex != -1) {
          _blueprint = _documents[bpIndex];
        } else {
          _blueprint = null;
        }

        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load dashboard: $e';
      });
    }
  }

  Future<void> _generateBlueprint() async {
    if (_generatingBlueprint) return;
    setState(() {
      _generatingBlueprint = true;
    });

    try {
      final response = await _http.generateBlueprint(widget.startup.id);
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && body['ok'] == true) {
        await _loadDashboardData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Startup Blueprint generated successfully!')),
          );
        }
      } else {
        throw Exception(body['error']?['message'] ?? 'Failed to generate blueprint');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generatingBlueprint = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((t) => t.status == 'done').length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.startup.startupName,
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Stage: ${totalTasks > 0 ? _tasks.first.stage.toUpperCase() : "IDEA"}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overview cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              // Roadmap progress card
              _buildMetricCard(
                title: 'Roadmap Execution',
                value: '${(completionRate * 100).toInt()}%',
                subtitle: '$completedTasks of $totalTasks tasks complete',
                icon: Icons.donut_large_rounded,
                iconColor: AppTheme.accent,
                progress: completionRate,
              ),
              // Documents count card
              _buildMetricCard(
                title: 'Business Docs',
                value: '${_documents.length}',
                subtitle: 'Generated formats: PDF & MD',
                icon: Icons.article_outlined,
                iconColor: AppTheme.primary,
              ),
              // Idea validator score card
              _buildMetricCard(
                title: 'Idea Status',
                value: widget.startup.validationReport != null ? 'VALIDATED' : 'STAGE 1',
                subtitle: widget.startup.validationReport != null ? 'Market report ready' : 'Idea stage',
                icon: Icons.offline_bolt_outlined,
                iconColor: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Startup Blueprint area
          Text(
            'Startup Blueprint',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _blueprint == null
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.architecture_rounded, size: 48, color: AppTheme.textSecondaryDark),
                      const SizedBox(height: 12),
                      Text(
                        'Generate Startup Blueprint',
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let our AI co-founder formulate your Problem Statement, Value Proposition, Target Audience, Revenue Model, and Distribution channels.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(fontSize: 13, color: AppTheme.textSecondaryDark),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _generatingBlueprint ? null : _generateBlueprint,
                        child: _generatingBlueprint
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Generate Blueprint'),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Corporate Core & Strategy',
                            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Icon(Icons.verified_user_rounded, color: AppTheme.success, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _blueprint!.content ?? '',
                        style: GoogleFonts.roboto(
                          fontSize: 14.5,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                        maxLines: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 32),

          // Startup Description
          Text(
            'Startup Description',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              widget.startup.description,
              style: GoogleFonts.roboto(
                fontSize: 14.5,
                color: Colors.white.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: iconColor,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ]
        ],
      ),
    );
  }
}
