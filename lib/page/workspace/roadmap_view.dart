import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startbuddy/models/startup.dart';
import 'package:startbuddy/models/task.dart';
import 'package:startbuddy/service/db/db_service.dart';
import 'package:startbuddy/service/http.dart';
import 'package:startbuddy/theme.dart';

class RoadmapView extends StatefulWidget {
  final Startup startup;

  const RoadmapView({super.key, required this.startup});

  @override
  State<RoadmapView> createState() => _RoadmapViewState();
}

class _RoadmapViewState extends State<RoadmapView>
    with SingleTickerProviderStateMixin {
  final DbService _db = DbService();
  final HttpService _http = HttpService();

  late TabController _tabController;
  bool _loading = true;
  bool _generating = false;
  List<StartupTask> _tasks = [];

  double _fontSize(
    BuildContext context,
    double base,
    double widthFactor, {
    double max = 18,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    return math.min(max, math.max(base, width * widthFactor)).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadTasks() async {
    try {
      setState(() => _loading = true);
      final data = await _db.fetchTasksForStartup(widget.startup.id);

      if (!mounted) return;
      setState(() {
        _tasks = data.map((t) => StartupTask.fromJson(t)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load roadmap tasks: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String get _currentStageName {
    return switch (_tabController.index) {
      0 => 'idea',
      1 => 'mvp',
      2 => 'growth',
      _ => 'idea',
    };
  }

  Future<void> _generateAIRoadmap() async {
    if (_generating) return;
    setState(() => _generating = true);

    try {
      final stage = _currentStageName;
      final response = await _http.generateRoadmap(widget.startup.id, stage);
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['ok'] == true) {
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Roadmap for ${stage.toUpperCase()} generated!'),
            ),
          );
        }
      } else {
        throw Exception(
          body['error']?['message'] ?? 'Failed to generate roadmap',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Roadmap error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<void> _toggleTaskStatus(StartupTask task) async {
    final newStatus = task.status == 'done' ? 'todo' : 'done';

    // Optimistic UI update
    setState(() {
      task.status = newStatus;
    });

    try {
      await _db.updateTaskStatus(task.id, newStatus);
    } catch (e) {
      // Revert if error
      setState(() {
        task.status = newStatus == 'done' ? 'todo' : 'done';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTask(StartupTask task) async {
    // Optimistic UI update
    setState(() {
      _tasks.remove(task);
    });

    try {
      await _db.deleteTask(task.id);
    } catch (e) {
      // Revert
      setState(() {
        _tasks.add(task);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogWidth = math
                .min(360, MediaQuery.sizeOf(context).width - 32)
                .toDouble();

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              backgroundColor: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Add Custom Task',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: _fontSize(context, 18, 0.05, max: 22),
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dialogWidth),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        maxLines: null,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Task Title',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: _fontSize(context, 14, 0.035, max: 16),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: math.max(
                          12,
                          MediaQuery.sizeOf(context).height * 0.02,
                        ),
                      ),
                      Text(
                        'Priority',
                        style: GoogleFonts.roboto(
                          fontSize: _fontSize(context, 12, 0.03, max: 14),
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      SizedBox(
                        height: math.max(
                          6,
                          MediaQuery.sizeOf(context).height * 0.01,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['low', 'medium', 'high'].map((p) {
                          final isSelected = priority == p;
                          return ChoiceChip(
                            label: Text(
                              p.toUpperCase(),
                              style: TextStyle(
                                fontSize: _fontSize(
                                  context,
                                  10,
                                  0.025,
                                  max: 12,
                                ),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.primary,
                            backgroundColor: AppTheme.darkCard,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => priority = p);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actionsOverflowAlignment: OverflowBarAlignment.end,
              actionsOverflowButtonSpacing: 8,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: _fontSize(context, 12, 0.03, max: 14),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(dialogContext);

                    try {
                      setState(() => _loading = true);
                      await _db.createTask(
                        startupId: widget.startup.id,
                        title: title,
                        priority: priority,
                        stage: _currentStageName,
                      );
                      await _loadTasks();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add task: $e'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: _fontSize(context, 12, 0.03, max: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(titleController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final currentStage = _currentStageName;
    final stageTasks = _tasks.where((t) => t.stage == currentStage).toList();

    return Column(
      children: [
        // TabBar headers
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondaryDark,
          tabs: const [
            Tab(text: 'IDEA STAGE'),
            Tab(text: 'MVP STAGE'),
            Tab(text: 'GROWTH STAGE'),
          ],
        ),

        // Action Buttons Row
        Padding(
          padding: EdgeInsets.fromLTRB(
            math.max(12, MediaQuery.of(context).size.width * 0.05),
            math.max(8, MediaQuery.of(context).size.height * 0.015),
            math.max(12, MediaQuery.of(context).size.width * 0.05),
            math.max(4, MediaQuery.of(context).size.height * 0.01),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 380;
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppTheme.accent,
                      size: 24,
                    ),
                    tooltip: 'Add Custom Task',
                    onPressed: _showAddTaskDialog,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: GoogleFonts.roboto(
                        fontSize: _fontSize(context, 11, 0.025, max: 13),
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: AppTheme.primary,
                    ),
                    onPressed: _generating ? null : _generateAIRoadmap,
                    icon: _generating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, size: 14),
                    label: Text(_generating ? 'Generating...' : 'AI Generate'),
                  ),
                ],
              );

              final countLabel = Text(
                '${stageTasks.length} Action Items',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryDark,
                  fontSize: _fontSize(context, 12, 0.03, max: 14),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [countLabel, const SizedBox(height: 8), actions],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  countLabel,
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: actions,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Tasks list
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : stageTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        size: 48,
                        color: Colors.white.withOpacity(0.12),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'No roadmap tasks for this stage.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: AppTheme.textSecondaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Click "AI Generate" to bootstrap your tasks!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: AppTheme.textSecondaryDark.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width < 420
                        ? 12
                        : 20,
                    vertical: 10,
                  ),
                  itemCount: stageTasks.length,
                  itemBuilder: (context, index) {
                    final task = stageTasks[index];
                    final isDone = task.status == 'done';

                    Color priorityColor = switch (task.priority) {
                      'high' => AppTheme.error,
                      'medium' => AppTheme.warning,
                      _ => AppTheme.success,
                    };

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDone
                              ? Colors.green.withOpacity(0.2)
                              : Colors.white.withOpacity(0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            activeColor: AppTheme.success,
                            value: isDone,
                            onChanged: (_) => _toggleTaskStatus(task),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDone
                                        ? Colors.white.withOpacity(0.4)
                                        : Colors.white,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: priorityColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      task.priority.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            onPressed: () => _deleteTask(task),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
