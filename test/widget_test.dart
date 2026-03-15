import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:translator/main.dart';
import 'package:translator/presenters/translation_presenter.dart';

void main() {
  testWidgets('Translation UI Check', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TranslationPresenter()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the title is present
    expect(find.text('Select Translation Model:'), findsOneWidget);
    expect(find.text('Translation Output:'), findsOneWidget);
  });
}
