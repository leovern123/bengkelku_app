import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bengkelku_app/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BengkelKuApp());

    expect(find.text('BENGKELKU'), findsOneWidget);
    expect(find.byIcon(Icons.car_repair), findsOneWidget);
  });
}
