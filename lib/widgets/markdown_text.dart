import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkdownText extends StatelessWidget {
  const MarkdownText({
    super.key,
    required this.text,
    this.maxLines,
    this.overflow,
    this.padding,
  });

  final String text;
  final int? maxLines;
  final TextOverflow? overflow;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final normalized = text.trim();

    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }

    final blocks = _splitBlocks(normalized);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < blocks.length; index++) ...[
            _MarkdownBlock(
              block: blocks[index],
              maxLines: maxLines == null
                  ? null
                  : maxLines! - index > 1
                  ? maxLines! - index
                  : 1,
              overflow: overflow,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  List<String> _splitBlocks(String text) {
    final blocks = <String>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final current = <String>[];

    void flush() {
      if (current.isNotEmpty) {
        blocks.add(current.join('\n'));
        current.clear();
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      final isList = RegExp(r'^(\d+\.|-|\*|\+)\s+').hasMatch(line);
      final isHeading = RegExp(r'^#{1,6}\s+').hasMatch(line);

      if (line.isEmpty) {
        flush();
        continue;
      }

      if (current.isNotEmpty) {
        final previous = current.last.trim();
        final previousIsList = RegExp(
          r'^(\d+\.|-|\*|\+)\s+',
        ).hasMatch(previous);
        if ((isList || previousIsList) &&
            !isHeading &&
            !previous.startsWith('#')) {
          current.add(line);
          continue;
        }
      }

      if (current.isNotEmpty) flush();
      current.add(line);
    }

    flush();
    return blocks;
  }
}

class _MarkdownBlock extends StatelessWidget {
  const _MarkdownBlock({required this.block, this.maxLines, this.overflow});

  final String block;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final firstLine = block.split('\n').first.trim();

    if (firstLine.startsWith('######')) {
      return _TextBlock(
        text: firstLine.replaceFirst('######', '').trim(),
        style: _heading6,
      );
    }
    if (firstLine.startsWith('#####')) {
      return _TextBlock(
        text: firstLine.replaceFirst('#####', '').trim(),
        style: _heading5,
      );
    }
    if (firstLine.startsWith('####')) {
      return _TextBlock(
        text: firstLine.replaceFirst('####', '').trim(),
        style: _heading4,
      );
    }
    if (firstLine.startsWith('###')) {
      return _TextBlock(
        text: firstLine.replaceFirst('###', '').trim(),
        style: _heading3,
      );
    }
    if (firstLine.startsWith('##')) {
      return _TextBlock(
        text: firstLine.replaceFirst('##', '').trim(),
        style: _heading2,
      );
    }
    if (firstLine.startsWith('#')) {
      return _TextBlock(
        text: firstLine.replaceFirst('#', '').trim(),
        style: _heading1,
      );
    }

    final lines = block.split('\n');
    if (lines.every(
      (line) => RegExp(r'^(\d+\.|-|\*|\+)\s+').hasMatch(line.trim()),
    )) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .where((line) => line.trim().isNotEmpty)
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 2),
                    Text(
                      '•',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InlineMarkdownText(
                        text: line.trim().replaceFirst(
                          RegExp(r'^(\d+\.|-|\*|\+)\s+'),
                          '',
                        ),
                        maxLines: maxLines,
                        overflow: overflow,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }

    return _InlineMarkdownText(
      text: block,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  static final TextStyle _heading1 = GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.25,
  );
  static final TextStyle _heading2 = GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.3,
  );
  static final TextStyle _heading3 = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.35,
  );
  static final TextStyle _heading4 = GoogleFonts.roboto(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.35,
  );
  static final TextStyle _heading5 = GoogleFonts.roboto(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.35,
  );
  static final TextStyle _heading6 = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.35,
  );
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style);
  }
}

class _InlineMarkdownText extends StatelessWidget {
  const _InlineMarkdownText({required this.text, this.maxLines, this.overflow});

  final String text;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(text);

    return RichText(
      text: TextSpan(
        style: GoogleFonts.roboto(
          fontSize: 14.5,
          color: Colors.white,
          height: 1.5,
        ),
        children: spans,
      ),
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : overflow!,
    );
  }

  List<TextSpan> _buildSpans(String text) {
    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`|https?:\/\/[^\s)]+)',
    );
    var start = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final token = match.group(0)!;
      if (token.startsWith('**') && token.endsWith('**')) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (token.startsWith('`') && token.endsWith('`')) {
        spans.add(TextSpan(text: token.substring(1, token.length - 1)));
      } else {
        spans.add(
          TextSpan(
            text: token,
            style: const TextStyle(color: Color(0xFF8AB4F8)),
          ),
        );
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }
}
