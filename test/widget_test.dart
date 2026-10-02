// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rugido_sin_hambre/features/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('opens the student profile from the dashboard avatar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardScreen()),
    );

    await tester.tap(find.byTooltip('Abrir perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre del Alumno'), findsOneWidget);
    expect(find.byTooltip('Regresar al dashboard'), findsOneWidget);

    await tester.tap(find.byTooltip('Regresar al dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Mi dashboard'), findsOneWidget);
    expect(find.text('0 L de X L consumidos'), findsOneWidget);
    expect(find.text('0 kcal de X kcal consumidas'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.text('Registrar litros'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Registrar litros'), findsOneWidget);
    expect(
      find.widgetWithText(TextButton, 'Registrar calorías'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Registrar litros'));
    await tester.pumpAndSettle();
    expect(find.text('Litros consumidos'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Registrar'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Litros consumidos'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Registrar litros'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar'));
    await tester.pumpAndSettle();
    expect(find.text('Litros consumidos'), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(TextButton, 'Registrar calorías'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Registrar calorías'));
    await tester.pumpAndSettle();

    expect(find.text('Escanea tu alimento'), findsOneWidget);
    expect(find.text('Vista de cámara'), findsOneWidget);
    expect(find.text('El escaneo con cámara estará disponible próximamente.'), findsOneWidget);

    await tester.ensureVisible(find.text('Ingresar alimento manualmente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingresar alimento manualmente'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre del alimento'), findsOneWidget);
    expect(find.text('Calorías'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Registrar'), findsOneWidget);
  });

  testWidgets('opens the menu food screen from the bottom-left navigation bar icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardScreen()),
    );

    expect(find.byTooltip('Menú'), findsOneWidget);
    await tester.tap(find.byTooltip('Menú'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Menú'), findsOneWidget);
    expect(find.text('De emprendedores'), findsOneWidget);
    expect(find.text('Menu de locales'), findsOneWidget);

    await tester.tap(find.byTooltip('Regresar'));
    await tester.pumpAndSettle();

    expect(find.text('Mi dashboard'), findsOneWidget);
  });
}
