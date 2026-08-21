import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/widgets/simulated_rewarded_ad.dart';

void main() {
  testWidgets('simulated ad rewards only after claim', (tester) async {
    var result = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await SimulatedRewardedAd.show(context);
                },
                child: const Text('go'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.widgetWithText(FilledButton, 'Claim reward'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
