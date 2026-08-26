import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/app/maanthirigam_app.dart';
import 'package:maanthirigam/core/constants/app_constants.dart';

void main() {
  testWidgets('foundation placeholder renders app name', (tester) async {
    await tester.pumpWidget(const MaanthirigamApp());
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
