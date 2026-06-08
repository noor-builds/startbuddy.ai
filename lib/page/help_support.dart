import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

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
                    Icons.help_outline_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Help & Support',
                    style: GoogleFonts.openSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _HelpItem(
                    icon: Icons.forum_outlined,
                    label: 'FAQs',
                    description: 'Find answers to common questions.',
                  ),
                  _HelpItem(
                    icon: Icons.mail_outline,
                    label: 'Contact Us',
                    description: 'Reach out to our support team.',
                  ),
                  _HelpItem(
                    icon: Icons.description_outlined,
                    label: 'Documentation',
                    description: 'Learn how to use startbuddy.ai.',
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

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1528).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(153, 11, 17, 19).withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D4FF), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 0.3),
            size: 20,
          ),
        ],
      ),
    );
  }
}
