import 'package:flutter_test/flutter_test.dart';
import 'package:roadguard_dashcam/app.dart';

void main() {
  testWidgets('App launches splash', (WidgetTester tester) async {
    await tester.pumpWidget(const RoadGuardApp());
    expect(find.text('RoadGuard'), findsOneWidget);
  });
}
