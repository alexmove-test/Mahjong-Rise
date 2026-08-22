import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/widgets/win_burst.dart';
import 'package:mahjong/widgets/win_overlay.dart';

Widget _host({
  required int stars,
  required bool hasNext,
  required bool nextUnlocked,
  bool isNewBest = false,
  bool unlockedNext = false,
  VoidCallback? onMap,
  VoidCallback? onNext,
  VoidCallback? onRetry,
}) {
  return MaterialApp(
    home: WinOverlay(
      levelId: 3,
      levelTitle: 'Пруд',
      score: 1250,
      stars: stars,
      isNewBest: isNewBest,
      unlockedNext: unlockedNext,
      hasNext: hasNext,
      nextUnlocked: nextUnlocked,
      onMap: onMap ?? () {},
      onNext: onNext ?? () {},
      onRetry: onRetry ?? () {},
      layout: WinBurstLayout.generate(count: 8, shardCount: 4, rayCount: 4),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows score, filled stars and Next when unlocked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(stars: 3, hasNext: true, nextUnlocked: true, isNewBest: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Победа!'), findsOneWidget);
    expect(find.text('Счёт: 1250'), findsOneWidget);
    expect(find.text('Уровень 3 · Пруд'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    expect(find.text('Дальше'), findsOneWidget);
    expect(find.text('Ещё раз'), findsNothing);
    expect(find.text('Карта'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows Play again when the next level is locked', (tester) async {
    await tester.pumpWidget(
      _host(stars: 1, hasNext: true, nextUnlocked: false, unlockedNext: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Счёт: 1250'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
    expect(find.text('Ещё раз'), findsOneWidget);
    expect(find.text('Дальше'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('primary buttons invoke callbacks', (tester) async {
    var next = 0;
    var map = 0;

    await tester.pumpWidget(
      _host(
        stars: 2,
        hasNext: true,
        nextUnlocked: true,
        onNext: () => next++,
        onMap: () => map++,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Дальше'));
    await tester.tap(find.text('Карта'));
    expect(next, 1);
    expect(map, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
