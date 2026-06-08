import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:startbuddy/models/startup.dart';

class Startupbox extends StatelessWidget {
  const Startupbox({super.key, required this.startup});

  final Startup startup;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/workspace/${startup.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    startup.startupName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.white.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              startup.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
