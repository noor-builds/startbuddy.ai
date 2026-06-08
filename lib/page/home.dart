import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startbuddy/service/auth/auth_service.dart';
import 'package:startbuddy/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final TextEditingController promptcontroller = TextEditingController();

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width > 600 ? 48.0 : 24.0;

    return Scaffold(
      drawer: const _HomeDrawer(),
      body: Builder(
        builder: (scaffoldContext) => DecoratedBox(
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
              stops: [0.0, 0.3, 0.65, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -60,
                child: _GlowOrb(
                  size: 360,
                  color: AppTheme.accent.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -40,
                child: _GlowOrb(
                  size: 280,
                  color: AppTheme.primary.withValues(alpha: 0.06),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                    icon: Icon(
                      Icons.menu_rounded,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    tooltip: 'Menu',
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 40,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: size.width > 600 ? 260 : 220,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your personalized\nAI Co-founder',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: size.width > 600 ? 32 : 28,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: Colors.white,
                              letterSpacing: -1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Turn your ideas into reality with AI guidance.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 42),
                          Center(
                            child: Container(
                              width: 850,
                              constraints: const BoxConstraints(
                                minHeight: 90,
                                maxHeight: 220,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0A1528,
                                ).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color.fromARGB(
                                    153,
                                    11,
                                    17,
                                    19,
                                  ).withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: promptcontroller,
                                      minLines: 3,
                                      maxLines: 8,
                                      keyboardType: TextInputType.multiline,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Tell us about your startup so that we can help you take your dream to reality....',
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.38,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () {
                                      final idea = promptcontroller.text.trim();
                                      if (idea.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Describe your startup idea first.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }
                                      context.push('/validate', extra: idea);
                                    },
                                    icon: Icon(
                                      Icons.arrow_upward,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final email = auth.currentUser?.email ?? 'Account';

    return Drawer(
      backgroundColor: const Color(0xFF060E1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 160,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    email,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerTile(
                    icon: Icons.rocket_launch_outlined,
                    label: 'My Startups',
                    onTap: () => context.go('/my-startups'),
                  ),
                  _DrawerTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'New Chat',
                    selected: true,
                    onTap: () {
                      promptcontroller.clear();
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.feedback_outlined,
                    label: 'Feedback',
                    onTap: () => _navigateAndCloseDrawer(context, '/feedback'),
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _navigateAndCloseDrawer(context, '/settings'),
                  ),
                  _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => _navigateAndCloseDrawer(context, '/help-support'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            _DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              onTap: () async {
                Navigator.pop(context);
                await auth.signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateAndCloseDrawer(BuildContext context, String route) {
    Navigator.pop(context);
    context.push(route);
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppTheme.accent
        : Colors.white.withValues(alpha: 0.85);

    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: color,
        ),
      ),
      selected: selected,
      selectedTileColor: AppTheme.accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
