import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MahjongApp starts without errors', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MahjongApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('MAHJONG RISE'), findsOneWidget);
  });
}
