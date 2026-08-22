import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/widgets/tray_full_dialog.dart';

void main() {
  testWidgets('continue is the primary action when ads are available', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        home: TrayFullDialog(
          levelTitle: 'Sprout',
          score: 120,
          canContinue: true,
          onContinue: () => continued = true,
          onRetry: () {},
          onMap: () {},
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Courtyard'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    expect(continued, isTrue);
  });

  testWidgets('hides continue when ads cannot revive the hand', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TrayFullDialog(
          levelTitle: 'Sprout',
          score: 0,
          canContinue: false,
          onContinue: () {},
          onRetry: () {},
          onMap: () {},
        ),
      ),
    );

    expect(find.text('Continue'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
