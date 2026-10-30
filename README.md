# Inventario Inteligente

Aplicación móvil en Flutter para administrar productos de una pequeña tienda
o bodega: genera y lee códigos de barras (Code 128) y QR, y registra entradas,
salidas y ajustes de inventario con trazabilidad completa.

Proyecto de cierre de la asignatura **Programación de Dispositivos Móviles II**,
UMES Universidad Mesoamericana.

## Funcionalidades

- **Inicio:** resumen del inventario, alertas de stock bajo, búsqueda por
  código de productos activos y accesos rápidos (crear producto, listado
  completo y escáner).
- **Productos:** listado con búsqueda y filtros (activos e inactivos),
  creación y edición con fotografía opcional.
- **Etiquetas:** generación de código de barras Code 128 y QR por producto,
  con opción de compartir/exportar la etiqueta para impresión.
- **Escáner:** lectura de códigos con la cámara y búsqueda manual por código
  o nombre.
- **Movimientos:** entradas (compra/devolución), salidas (venta/daño) y
  ajustes por conteo físico con justificación obligatoria.
- **Historial y reportes:** historial filtrable por producto, tipo y fechas,
  valor del inventario y exportación a CSV.

## Requisitos técnicos

- Flutter y Dart (`sdk: ^3.13.5`).
- Interfaz **100% Cupertino (estilo iOS)**.
- Arquitectura **feature + domain** (presentación / dominio / datos por
  funcionalidad).
- Gestión de estado con `provider`.
- Persistencia local offline con `sqflite` (SQLite).
- Generación de códigos con `barcode_widget`; escaneo con `mobile_scanner`.

## Ejecución

```bash
flutter pub get
flutter run
```

Al abrir la aplicación por primera vez se precargan automáticamente
3 categorías y 15 productos de demostración con sus movimientos iniciales.

### Permisos

El escaneo requiere permiso de cámara. En Android se declara en
`AndroidManifest.xml` y en iOS en `Info.plist` (`NSCameraUsageDescription`).
**El escaneo debe probarse en un dispositivo físico.**

### Compilar el APK

```bash
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

### Pruebas

```bash
flutter analyze
flutter test
```

Las pruebas de `test/reglas_inventario_test.dart` validan las reglas de
negocio del inventario contra una base de datos SQLite en memoria.

## Arquitectura

```
lib/
├── main.dart
├── app/                  # CupertinoApp, tema y proveedores de estado
├── core/                 # Base de datos, errores y utilidades (CSV, formatos)
└── features/             # Una carpeta por funcionalidad
    ├── inicio/
    ├── productos/
    ├── escaner/
    ├── movimientos/
    └── reportes/
        ├── data/         # Repositorios que implementan SQLite
        ├── domain/       # Entidades, casos de uso y contratos de repositorio
        └── presentation/ # pages/, widgets/ y providers/
```

Las reglas de inventario viven en la capa de dominio
(`RegistrarMovimientoUseCase` y `ProductoUseCases`) y no dependen de los
widgets ni de la base de datos.

## Reglas de negocio

- Las cantidades de entrada y salida deben ser mayores que cero.
- No se permiten salidas superiores al stock disponible.
- El stock inicial se registra como movimiento de entrada (trazabilidad).
- Un producto con movimientos no se elimina; se desactiva.
- Los movimientos confirmados no se editan ni eliminan.
- El registro del movimiento y la actualización de existencias se ejecutan
  como una sola operación (transacción SQL).
