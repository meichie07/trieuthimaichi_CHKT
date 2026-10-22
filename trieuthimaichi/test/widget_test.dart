import 'package:flutter_test/flutter_test.dart';
import 'package:trieuthimaichi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KidGuardApp());
    expect(find.text('KID GUARD'), findsWidgets);
  });
}
