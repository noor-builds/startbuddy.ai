import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startbuddy/models/startup.dart';
import 'package:startbuddy/service/db/db_service.dart';
import 'package:startbuddy/widgets/startupbox.dart';

class MyStartups extends StatefulWidget {
  const MyStartups({super.key});

  @override
  State<MyStartups> createState() => _MyStartupsState();
}

class _MyStartupsState extends State<MyStartups> {
  List<Startup> _startups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStartups();
  }

  Future<void> _fetchStartups() async {
    try {
      final data = await DbService().fetchUserStartups();
      setState(() {
        _startups = data.map((json) => Startup.fromJson(json)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'My Startups',
                style: GoogleFonts.openSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_startups.length} startup${_startups.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _startups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.rocket_outlined,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  'No startups yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: _startups.length,
                            itemBuilder: (context, index) {
                              return Startupbox(startup: _startups[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
