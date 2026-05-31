import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startbuddy/service/http.dart';
import 'package:startbuddy/theme.dart';

/// Full-screen validation flow while [validator.ai] processes the startup idea.
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key, required this.prompt});

  final String prompt;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    _ValidationStep(
      label: 'Connect',
      log: 'Connecting to validator.ai…',
    ),
    _ValidationStep(
      label: 'Extract',
      log: 'Step 1/4 — Extracting startup name and description…',
    ),
    _ValidationStep(
      label: 'Research',
      log: 'Market research — analyzing competition and opportunity…',
    ),
    _ValidationStep(
      label: 'Report',
      log: 'Step 3/4 — Generating validation report (PDF)…',
    ),
    _ValidationStep(
      label: 'Save',
      log: 'Step 4/4 — Saving your startup record…',
    ),
  ];

  final List<_LogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  late final AnimationController _pulseController;

  int _activeStepIndex = 0;
  _ValidationStatus _status = _ValidationStatus.running;
  String? _errorMessage;
  String? _startupName;

  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _log('Validation session started.');
    _log('Idea received (${widget.prompt.trim().length} characters).');
    _startValidation();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  void _log(String message) {
    developer.log(message, name: 'validator.ai');
    if (!mounted) return;
    setState(() {
      _logs.add(_LogEntry(DateTime.now(), message));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(
          _logScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startValidation() {
    _advanceStep(0);
    _stepTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_status != _ValidationStatus.running) return;
      final next = (_activeStepIndex + 1).clamp(0, _steps.length - 1);
      if (next != _activeStepIndex) _advanceStep(next);
    });

    unawaited(_runValidation());
  }

  void _advanceStep(int index) {
    if (index == _activeStepIndex && _logs.isNotEmpty) {
      final last = _logs.last.message;
      if (last == _steps[index].log) return;
    }
    setState(() => _activeStepIndex = index);
    _log(_steps[index].log);
  }

  Future<void> _runValidation() async {
    _log('Sending request to validator.ai…');

    try {
      final response = await HttpService().validate(widget.prompt.trim());
      _log('Response received (HTTP ${response.statusCode}).');

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body is Map &&
          body['ok'] == true) {
        final data = body['data'];
        final name = data is Map ? data['startupName'] as String? : null;
        _onSuccess(startupName: name);
        return;
      }

      final message = _extractErrorMessage(body);
      _onFailure(message);
    } on HttpNetworkException catch (e, st) {
      developer.log(
        'Validation request failed (network)',
        name: 'validator.ai',
        error: e,
        stackTrace: st,
      );
      _onFailure(e.message);
    } catch (e, st) {
      developer.log(
        'Validation request failed',
        name: 'validator.ai',
        error: e,
        stackTrace: st,
      );
      _onFailure(e.toString());
    }
  }

  String _extractErrorMessage(dynamic body) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (body['message'] is String) return body['message'] as String;
    }
    return 'Validation failed. Please try again.';
  }

  void _onSuccess({String? startupName}) {
    _stepTimer?.cancel();
    setState(() {
      _status = _ValidationStatus.success;
      _activeStepIndex = _steps.length - 1;
      _startupName = startupName;
    });
    _log('Validation complete.');
    if (startupName != null && startupName.isNotEmpty) {
      _log('Startup saved as “$startupName”.');
    }
  }

  void _onFailure(String message) {
    _stepTimer?.cancel();
    setState(() {
      _status = _ValidationStatus.error;
      _errorMessage = message;
    });
    _log('Error: $message');
  }

  Future<void> _retry() async {
    setState(() {
      _status = _ValidationStatus.running;
      _errorMessage = null;
      _startupName = null;
      _activeStepIndex = 0;
      _logs.clear();
    });
    _log('Retrying validation…');
    _startValidation();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width > 600 ? 48.0 : 24.0;

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
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _status == _ValidationStatus.running
                      ? null
                      : () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white.withValues(
                      alpha: _status == _ValidationStatus.running ? 0.25 : 0.75,
                    ),
                  ),
                  tooltip: 'Back',
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusHeader(
                          status: _status,
                          pulse: _pulseController,
                          startupName: _startupName,
                        ),
                        const SizedBox(height: 32),
                        _StepProgress(
                          steps: _steps,
                          activeIndex: _activeStepIndex,
                          status: _status,
                        ),
                        const SizedBox(height: 28),
                        _IdeaPreview(prompt: widget.prompt),
                        const SizedBox(height: 24),
                        _ActivityLog(
                          entries: _logs,
                          scrollController: _logScroll,
                        ),
                        if (_status == _ValidationStatus.error) ...[
                          const SizedBox(height: 24),
                          _ErrorBanner(message: _errorMessage ?? 'Unknown error'),
                          const SizedBox(height: 16),
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
                        if (_status == _ValidationStatus.success) ...[
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.pop(),
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
    );
  }
}

enum _ValidationStatus { running, success, error }

class _ValidationStep {
  const _ValidationStep({required this.label, required this.log});

  final String label;
  final String log;
}

class _LogEntry {
  const _LogEntry(this.time, this.message);

  final DateTime time;
  final String message;
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.status,
    required this.pulse,
    this.startupName,
  });

  final _ValidationStatus status;
  final Animation<double> pulse;
  final String? startupName;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, icon, color) = switch (status) {
      _ValidationStatus.running => (
          'Validating your idea',
          'validator.ai is analyzing your startup',
          Icons.hub_outlined,
          AppTheme.accent,
        ),
      _ValidationStatus.success => (
          startupName != null ? startupName! : 'Validation complete',
          'Your startup report is ready',
          Icons.check_circle_outline_rounded,
          AppTheme.success,
        ),
      _ValidationStatus.error => (
          'Validation failed',
          'Something went wrong during analysis',
          Icons.error_outline_rounded,
          AppTheme.error,
        ),
    };

    return Column(
      children: [
        FadeTransition(
          opacity: status == _ValidationStatus.running
              ? Tween(begin: 0.55, end: 1.0).animate(pulse)
              : const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.8,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.5),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.steps,
    required this.activeIndex,
    required this.status,
  });

  final List<_ValidationStep> steps;
  final int activeIndex;
  final _ValidationStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final segmentIndex = i ~/ 2;
          final done = segmentIndex < activeIndex ||
              status == _ValidationStatus.success;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 22),
              color: done
                  ? AppTheme.accent.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final step = steps[stepIndex];
        final isActive = stepIndex == activeIndex &&
            status == _ValidationStatus.running;
        final isDone = stepIndex < activeIndex ||
            status == _ValidationStatus.success;
        final isError =
            status == _ValidationStatus.error && stepIndex == activeIndex;

        Color dotColor;
        Widget? child;
        if (isError) {
          dotColor = AppTheme.error;
          child = const Icon(Icons.close, size: 14, color: Colors.white);
        } else if (isDone) {
          dotColor = AppTheme.accent;
          child = const Icon(Icons.check, size: 14, color: Colors.white);
        } else if (isActive) {
          dotColor = AppTheme.accent;
          child = SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          );
        } else {
          dotColor = Colors.white.withValues(alpha: 0.15);
        }

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor.withValues(alpha: isDone || isActive ? 1 : 0.35),
              ),
              child: child,
            ),
            const SizedBox(height: 8),
            Text(
              step.label,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: Colors.white.withValues(
                  alpha: isActive || isDone ? 0.85 : 0.35,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _IdeaPreview extends StatelessWidget {
  const _IdeaPreview({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    final preview = prompt.trim();
    if (preview.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1528).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        preview.length > 180 ? '${preview.substring(0, 180)}…' : preview,
        style: GoogleFonts.roboto(
          fontSize: 13,
          height: 1.45,
          color: Colors.white.withValues(alpha: 0.55),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ActivityLog extends StatelessWidget {
  const _ActivityLog({
    required this.entries,
    required this.scrollController,
  });

  final List<_LogEntry> entries;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 168,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'Waiting for logs…',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final time = TimeOfDay.fromDateTime(entry.time)
                        .format(context);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$time  ',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                color: AppTheme.accent.withValues(alpha: 0.7),
                              ),
                            ),
                            TextSpan(
                              text: entry.message,
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.85),
          height: 1.4,
        ),
      ),
    );
  }
}
