import 'package:flutter_test/flutter_test.dart';
import 'package:redo_partner/main.dart';

void main() {
  testWidgets('Partner app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RedoPartnerApp());
  });
}
