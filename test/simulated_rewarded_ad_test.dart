import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/widgets/simulated_rewarded_ad.dart';

void main() {
  testWidgets('closing early does not grant a reward', (tester) async {
    var earned = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                earned = await SimulatedRewardedAd.show(
                  context,
                  watchDuration: const Duration(seconds: 2),
                );
              },
              child: const Text('show'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.tap(find.byTooltip('Close without reward'));
    await tester.pump();

    expect(earned, isFalse);
  });

  testWidgets('claiming after the countdown grants a reward', (tester) async {
    var earned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                earned = await SimulatedRewardedAd.show(
                  context,
                  watchDuration: const Duration(milliseconds: 400),
                );
              },
              child: const Text('show'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.text('Claim reward'), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Claim reward'));
    await tester.pump();

    expect(earned, isTrue);
  });

  testWidgets('finishing the clip auto-grants the reward', (tester) async {
    var earned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                earned = await SimulatedRewardedAd.show(
                  context,
                  watchDuration: const Duration(milliseconds: 400),
                );
              },
              child: const Text('show'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Claim reward'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(earned, isTrue);
  });
}
