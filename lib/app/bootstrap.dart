import 'package:flutter/widgets.dart';

import '../core/app_container.dart';
import 'maanthirigam_app.dart';

Future<void> bootstrap({AppContainer? container}) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaanthirigamApp(container: container ?? AppContainer.create()));
}
