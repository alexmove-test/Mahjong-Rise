import 'package:flutter_test/flutter_test.dart';
import 'package:icon_admin/main.dart';

void main() {
  testWidgets('admin app loads', (tester) async {
    await tester.pumpWidget(const IconAdminApp());
    await tester.pump();
    expect(find.byType(IconAdminPage), findsOneWidget);
  });
}
