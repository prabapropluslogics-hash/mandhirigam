import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/app/maanthirigam_app.dart';

import 'support/scripted_http.dart';
import 'support/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> platformCalls;

  setUp(() {
    platformCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall call) async {
      platformCalls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  bool exited() => platformCalls.contains('SystemNavigator.pop');

  Future<void> launch(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final ScriptedHttpClient client =
        ScriptedHttpClient(<String, http.Response>{
      'GET /api/v1/app-config': jsonOk(sampleAppConfig),
      'GET /api/v1/announcements': jsonOk(sampleAnnouncements),
      'GET /api/v1/books': jsonOk(sampleBooks),
    });
    await tester.pumpWidget(
      MaanthirigamApp(container: testContainer(httpClient: client)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
  }

  testWidgets('back on another tab returns to the Home tab', (tester) async {
    await launch(tester);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Browsing as guest'), findsOneWidget);

    await systemBack(tester);
    await tester.pumpAndSettle();
    expect(find.text('Browsing as guest'), findsNothing);
    expect(find.text('Press back again to exit'), findsNothing);
    expect(exited(), isFalse);
  });

  testWidgets('Home exits only on a second back within two seconds',
      (tester) async {
    await launch(tester);

    await systemBack(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Press back again to exit'), findsOneWidget);
    expect(exited(), isFalse);

    await tester.pump(const Duration(milliseconds: 2200));
    await systemBack(tester);
    expect(exited(), isFalse);

    await tester.pump(const Duration(milliseconds: 800));
    await systemBack(tester);
    expect(exited(), isTrue);

    await tester.pumpAndSettle();
  });
}
