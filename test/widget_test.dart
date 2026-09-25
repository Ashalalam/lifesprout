import 'package:flutter_test/flutter_test.dart';
import 'package:billsprout/main.dart';

void main() {
  testWidgets('BillSprout App loads clean login view', (WidgetTester tester) async {
    await tester.pumpWidget(const BillSproutApp());
    expect(find.text('Portal Access Login'), findsOneWidget);
  });
}
