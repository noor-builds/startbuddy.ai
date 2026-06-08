import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:startbuddy/service/http.dart';
import 'package:startbuddy/theme.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key, required this.prompt});

  final String prompt;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    'Understanding your idea',
    'Researching your market',
    'Building your report',
    'Saving everything',
  ];

  late final AnimationController _pulseController;

  int _stepIndex = 0;
  _Status _status = _Status.loading;
  String? _errorMessage;
  String? _startupName;
  int? _startupId;
  Map<String, dynamic>? _startupData;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _start();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
    _stepTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_status != _Status.loading) return;
      if (_stepIndex < _steps.length - 1) {
        setState(() => _stepIndex++);
      }
    });
    unawaited(_validate());
  }

  Future<void> _validate() async {
    final authId = Supabase.instance.client.auth.currentUser?.id;
    if (authId == null) {
      _finishError('You must be signed in to validate your idea.');
      return;
    }

    try {
      final response = await HttpService().validate(widget.prompt.trim());

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body is Map &&
          body['ok'] == true) {
        final data = body['data'];
        final startup = data is Map ? data['startup'] : null;
        final startupData = startup is Map
            ? Map<String, dynamic>.from(startup)
            : null;
        final name = data is Map ? data['startupName'] as String? : null;
        final id = startupData?['id'] as int?;
        _finishSuccess(name, id, startupData);
        return;
      }

      _finishError(_messageFromBody(body));
    } catch (e) {
      _finishError(_friendlyError(e));
    }
  }

  String _messageFromBody(dynamic body) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
    }
    return 'We could not validate your idea. Please try again.';
  }

  String _friendlyError(Object e) {
    if (e is http.ClientException || e.toString().contains('Failed to fetch')) {
      return 'We could not connect to StartBuddy right now. '
          'Please check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _finishSuccess(
    String? startupName,
    int? startupId,
    Map<String, dynamic>? startupData,
  ) {
    _stepTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _status = _Status.done;
      _stepIndex = _steps.length - 1;
      _startupName = startupName;
      _startupId = startupId;
      _startupData = startupData;
    });
  }

  void _finishError(String message) {
    _stepTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _status = _Status.error;
      _errorMessage = message;
    });
  }

  void _retry() {
    setState(() {
      _status = _Status.loading;
      _errorMessage = null;
      _startupName = null;
      _startupData = null;
      _stepIndex = 0;
    });
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.sizeOf(context).width > 600 ? 48.0 : 24.0;

    return Scaffold(
      body: DecoratedBox(
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
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _status == _Status.loading
                        ? null
                        : () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white.withValues(
                        alpha: _status == _Status.loading ? 0.25 : 0.75,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildIcon(),
                          const SizedBox(height: 28),
                          Text(
                            _title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.5),
                              height: 1.45,
                            ),
                          ),
                          if (_status == _Status.loading) ...[
                            const SizedBox(height: 36),
                            const LinearProgressIndicator(
                              minHeight: 3,
                              borderRadius: BorderRadius.all(
                                Radius.circular(4),
                              ),
                              backgroundColor: Color(0xFF1E293B),
                              color: AppTheme.accent,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _steps[_stepIndex],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                          if (_status == _Status.error) ...[
                            const SizedBox(height: 28),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.pop(),
                                    child: const Text('Go back'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _retry,
                                    child: const Text('Try again'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_status == _Status.done) ...[
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _startupId == null || _startupData == null
                                  ? null
                                  : () {
                                      context.go('/workspace/$_startupId');
                                    },
                              child: const Text('Continue'),
                            ),
                          ],
                        ],
                      ),
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

  String get _title => switch (_status) {
    _Status.loading => 'Working on your idea',
    _Status.done =>
      _startupName != null ? '$_startupName is ready' : 'You are all set',
    _Status.error => 'Something went wrong',
  };

  String get _subtitle => switch (_status) {
    _Status.loading =>
      'This usually takes a few minutes. Hang tight while we validate your startup.',
    _Status.done => 'Your validation report has been created.',
    _Status.error => 'Do not worry — your idea is still saved on this screen.',
  };

  Widget _buildIcon() {
    if (_status == _Status.loading) {
      return FadeTransition(
        opacity: Tween(begin: 0.5, end: 1.0).animate(_pulseController),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.accent,
          ),
        ),
      );
    }

    final isDone = _status == _Status.done;
    return Icon(
      isDone ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
      size: 56,
      color: isDone ? AppTheme.success : AppTheme.error,
    );
  }
}

enum _Status { loading, done, error }
