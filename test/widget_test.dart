import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doctor_app/src/app.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/session/session_storage.dart';

void main() {
  testWidgets('App starts and shows role screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = SessionStorage();
    final initialState = await storage.read();
    final controller = SessionController(initialState: initialState, storage: storage);

    await tester.pumpWidget(DoctorApp(sessionController: controller));
    await tester.pumpAndSettle();

    // Splash waits ~1.4s then routes to role screen.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Choose your role'), findsOneWidget);
    expect(find.text('Lady Health Worker'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
  });
}
