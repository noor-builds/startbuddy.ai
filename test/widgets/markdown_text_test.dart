import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startbuddy/widgets/markdown_text.dart';

void main() {
  testWidgets('renders limited markdown without an explicit overflow mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownText(
            text: '## Startup Blueprint\n\nA generated startup strategy.',
            maxLines: 12,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Startup Blueprint'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('A generated startup strategy.'),
      ),
      findsOneWidget,
    );
  });
}
