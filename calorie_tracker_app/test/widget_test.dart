import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calorie_tracker_app/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CalorieTrackerApp()));

    expect(find.text('Snap & Track'), findsOneWidget);
  });
}
