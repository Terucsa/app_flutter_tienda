import 'package:app_tienda/app/tema.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la aplicación utiliza un tema Cupertino (estilo iOS)', () {
    final CupertinoThemeData tema = TemaApp.temaCupertino();
    expect(tema.primaryColor, TemaApp.colorPrimario);
  });

  testWidgets('los widgets Cupertino se renderizan correctamente',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('Inventario Inteligente'),
          ),
          child: Center(
            child: CupertinoButton(
              onPressed: null,
              child: Text('Crear producto'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Inventario Inteligente'), findsOneWidget);
    expect(find.text('Crear producto'), findsOneWidget);
    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    expect(find.byType(CupertinoButton), findsOneWidget);
  });
}
