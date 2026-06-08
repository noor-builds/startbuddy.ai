import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width > 600 ? 48.0 : 24.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Container(
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Settings',
                    style: GoogleFonts.openSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _SettingTile(
                    icon: Icons.color_lens_outlined,
                    label: 'Theme',
                    trailing: const Text(
                      'Dark',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  _SettingTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: const Color(0xFF6C63FF),
                    ),
                  ),
                  _SettingTile(
                    icon: Icons.language_outlined,
                    label: 'Language',
                    trailing: const Text(
                      'English',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1528).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(153, 11, 17, 19).withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D4FF), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
