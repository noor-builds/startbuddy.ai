import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startbuddy/models/startup.dart';
import 'package:startbuddy/service/db/db_service.dart';
import 'package:startbuddy/theme.dart';

// Import Workspace Views
import 'package:startbuddy/page/workspace/dashboard_view.dart';
import 'package:startbuddy/page/workspace/chat_view.dart';
import 'package:startbuddy/page/workspace/roadmap_view.dart';
import 'package:startbuddy/page/workspace/documents_view.dart';

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
  bool _drawerOpen = false;

  // Active Navigation Index
  // 0: Dashboard, 1: AI Chat, 2: Roadmap/Tasks, 3: Documents
  int _activeViewIndex = 0;

  static const Color _gradientTop = Color(0xFF01001a);
  static const Color _gradientMid1 = Color(0xFF030A18);
  static const Color _gradientMid2 = Color(0xFF0A1E36);
  static const Color _gradientEnd = Color(0xFF0D2247);

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

  void _toggleDrawer() {
    setState(() {
      _drawerOpen = !_drawerOpen;
    });
  }

  void _setViewIndex(int index) {
    setState(() {
      _activeViewIndex = index;
      _drawerOpen = false; // Close drawer on mobile
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WorkspaceBackground(
        gradientTop: _gradientTop,
        gradientMid1: _gradientMid1,
        gradientMid2: _gradientMid2,
        gradientEnd: _gradientEnd,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            : WorkspaceBody(
                startup: _startup!,
                activeViewIndex: _activeViewIndex,
                drawerOpen: _drawerOpen,
                onToggleDrawer: _toggleDrawer,
                onSelectView: _setViewIndex,
              ),
      ),
    );
  }
}

class WorkspaceBackground extends StatelessWidget {
  const WorkspaceBackground({
    super.key,
    required this.gradientTop,
    required this.gradientMid1,
    required this.gradientMid2,
    required this.gradientEnd,
    required this.child,
  });

  final Color gradientTop;
  final Color gradientMid1;
  final Color gradientMid2;
  final Color gradientEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientTop, gradientMid1, gradientMid2, gradientEnd],
          stops: const [0.0, 0.3, 0.65, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class WorkspaceBody extends StatelessWidget {
  const WorkspaceBody({
    super.key,
    required this.startup,
    required this.activeViewIndex,
    required this.drawerOpen,
    required this.onToggleDrawer,
    required this.onSelectView,
  });

  final Startup startup;
  final int activeViewIndex;
  final bool drawerOpen;
  final VoidCallback onToggleDrawer;
  final Function(int) onSelectView;

  double _clampDouble(double value, double min, double max) {
    return math.min(max, math.max(min, value));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 720;
          final mobileTitleSize = _clampDouble(
            constraints.maxWidth * 0.045,
            16,
            20,
          );

          return isMobile
              ? Stack(
                  children: [
                    Column(
                      children: [
                        // Custom Mobile Top Bar
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _clampDouble(
                              constraints.maxWidth * 0.05,
                              12,
                              20,
                            ),
                            vertical: _clampDouble(
                              constraints.maxHeight * 0.02,
                              8,
                              16,
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: onToggleDrawer,
                              ),
                              SizedBox(
                                width: _clampDouble(
                                  constraints.maxWidth * 0.03,
                                  6,
                                  12,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _viewTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: mobileTitleSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: _buildActiveView()),
                      ],
                    ),
                    if (drawerOpen) ...[
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: onToggleDrawer,
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        top: 0,
                        bottom: 0,
                        left: drawerOpen ? 0 : -280,
                        child: WorkspaceDrawer(
                          activeViewIndex: activeViewIndex,
                          onSelectView: onSelectView,
                          isMobile: true,
                          maxWidth: constraints.maxWidth,
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkspaceDrawer(
                      activeViewIndex: activeViewIndex,
                      onSelectView: onSelectView,
                      isMobile: false,
                      maxWidth: constraints.maxWidth,
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(
                          _clampDouble(constraints.maxWidth * 0.02, 12, 20),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF030914).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _buildActiveView(),
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  String get _viewTitle {
    return switch (activeViewIndex) {
      0 => 'Dashboard',
      1 => 'AI Co-Founder Chat',
      2 => 'Execution Roadmap',
      3 => 'Business vault',
      _ => 'StartBuddy',
    };
  }

  Widget _buildActiveView() {
    return switch (activeViewIndex) {
      0 => DashboardView(startup: startup),
      1 => ChatView(startup: startup),
      2 => RoadmapView(startup: startup),
      3 => DocumentsView(startup: startup),
      _ => DashboardView(startup: startup),
    };
  }
}

class WorkspaceDrawer extends StatelessWidget {
  const WorkspaceDrawer({
    super.key,
    required this.activeViewIndex,
    required this.onSelectView,
    required this.isMobile,
    required this.maxWidth,
  });

  final int activeViewIndex;
  final Function(int) onSelectView;
  final bool isMobile;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final drawerWidth = isMobile ? math.min(280.0, maxWidth * 0.82) : 280.0;

    return Container(
      width: drawerWidth,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF081121),
        borderRadius: isMobile
            ? const BorderRadius.horizontal(right: Radius.circular(28))
            : const BorderRadius.only(
                topRight: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.rocket_launch_rounded,
                        color: AppTheme.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'StartBuddy',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Founder\'s Operating System',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _DrawerItem(
                    label: 'Dashboard',
                    icon: Icons.dashboard_customize_outlined,
                    selected: activeViewIndex == 0,
                    onTap: () => onSelectView(0),
                  ),
                  _DrawerItem(
                    label: 'AI Co-Founder Chat',
                    icon: Icons.psychology_outlined,
                    selected: activeViewIndex == 1,
                    onTap: () => onSelectView(1),
                  ),
                  _DrawerItem(
                    label: 'Execution Roadmap',
                    icon: Icons.checklist_rtl_rounded,
                    selected: activeViewIndex == 2,
                    onTap: () => onSelectView(2),
                  ),
                  _DrawerItem(
                    label: 'Business Vault',
                    icon: Icons.folder_shared_outlined,
                    selected: activeViewIndex == 3,
                    onTap: () => onSelectView(3),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: Colors.white12, height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.exit_to_app_rounded,
              color: AppTheme.error,
              size: 20,
            ),
            title: Text(
              'Back to Startups',
              style: GoogleFonts.roboto(color: Colors.white70, fontSize: 14),
            ),
            onTap: () {
              Navigator.of(context).pop(); // Go back to startups screen
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.accent;
    final inactiveColor = Colors.white.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppTheme.primary.withOpacity(0.25)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          icon,
          color: selected ? activeColor : inactiveColor,
          size: 20,
        ),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w400,
            color: selected ? Colors.white : inactiveColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
