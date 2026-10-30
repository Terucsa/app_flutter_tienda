import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../app/tema.dart';
import '../../../productos/domain/producto.dart';
import '../../../productos/presentation/pages/producto_detalle_page.dart';
import '../../../movimientos/presentation/pages/movimiento_page.dart';
import '../providers/escaner_provider.dart';

/// Escáner de códigos de barras (Code 128) y QR con la cámara,
/// con alternativa de búsqueda manual por código o nombre.
class EscanerPage extends StatefulWidget {
  const EscanerPage({super.key});

  @override
  State<EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<EscanerPage> {
  late final MobileScannerController _controller;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.code128, BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _procesarCodigo(String? codigo) async {
    if (codigo == null || codigo.trim().isEmpty || _procesando) return;
    _procesando = true;
    final EscanerProvider provider = context.read<EscanerProvider>();
    try {
      final resultado = await provider.buscarPorCodigo(codigo);
      if (!mounted) return;
      if (resultado.encontrado) {
        await _mostrarProducto(resultado.producto!);
      } else {
        await _mostrarNoRegistrado(codigo.trim());
      }
    } finally {
      _procesando = false;
    }
  }

  Future<void> _mostrarProducto(Producto producto) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(producto.nombre),
        content: Column(
          children: [
            Text('Código: ${producto.codigo}'),
            const SizedBox(height: 4),
            Text(
              'Existencias: ${producto.stock} unidades',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: producto.stockBajo
                    ? TemaApp.colorPeligro
                    : TemaApp.colorExito,
              ),
            ),
            if (producto.stockBajo)
              const Text(
                'Alerta: stock igual o inferior al mínimo.',
                style: TextStyle(fontSize: 12, color: TemaApp.colorPeligro),
              ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              _irDetalle(producto);
            },
            child: const Text('Ver detalle'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _irMovimiento(producto);
            },
            child: const Text('Registrar movimiento'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarNoRegistrado(String codigo) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Icon(
          CupertinoIcons.exclamationmark_triangle_fill,
          color: TemaApp.colorAdvertencia,
          size: 40,
        ),
        content: Text(
          'El código "$codigo" no está registrado.\n'
          'Registre el producto antes de utilizarlo.',
          textAlign: TextAlign.center,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _irDetalle(Producto producto) {
    if (!mounted) return;
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ProductoDetallePage(productoId: producto.id!),
      ),
    );
  }

  void _irMovimiento(Producto producto) {
    if (!mounted) return;
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => MovimientoPage(productoId: producto.id),
      ),
    );
  }

  void _abrirBusquedaManual() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => const _BusquedaManualSheet(),
    );
  }

  Widget _construirError(BuildContext context, MobileScannerException error) {
    final String mensaje = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'Permiso de cámara denegado. Habilítelo en los ajustes del dispositivo.'
        : 'No se pudo iniciar la cámara. Verifique que el dispositivo tenga una cámara disponible.';
    return Container(
      color: TemaApp.colorFondo,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 48,
            color: TemaApp.colorPeligro,
          ),
          const SizedBox(height: 16),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          CupertinoButton(
            color: TemaApp.colorPrimario,
            borderRadius: BorderRadius.circular(10),
            onPressed: () => _controller.start(),
            child: const Text(
              'Reintentar',
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Escanear código'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: _abrirBusquedaManual,
          child: const Icon(
            CupertinoIcons.search,
            color: TemaApp.colorPrimario,
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: (captura) {
                  final codigo = captura.barcodes
                      .map((codigo) => codigo.rawValue)
                      .firstWhere(
                        (valor) => valor != null && valor.isNotEmpty,
                        orElse: () => null,
                      );
                  _procesarCodigo(codigo);
                },
                errorBuilder: _construirError,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'Apunte la cámara a un código de barras o QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.white, fontSize: 14),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    padding: const EdgeInsets.all(12),
                    onPressed: () => _controller.toggleTorch(),
                    child: const Icon(
                      CupertinoIcons.lightbulb_fill,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  CupertinoButton(
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    onPressed: _abrirBusquedaManual,
                    child: const Text(
                      'Búsqueda manual',
                      style: TextStyle(
                        color: CupertinoColors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_procesando)
              Container(
                color: CupertinoColors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: CupertinoActivityIndicator(radius: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hoja modal para buscar un producto manualmente por código o nombre.
class _BusquedaManualSheet extends StatefulWidget {
  const _BusquedaManualSheet();

  @override
  State<_BusquedaManualSheet> createState() => _BusquedaManualSheetState();
}

class _BusquedaManualSheetState extends State<_BusquedaManualSheet> {
  @override
  Widget build(BuildContext context) {
    final EscanerProvider provider = context.watch<EscanerProvider>();
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      color: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CupertinoSearchTextField(
                placeholder: 'Buscar por código o nombre',
                autofocus: true,
                onChanged: provider.buscarManual,
              ),
            ),
            Expanded(
              child: provider.buscando
                  ? const Center(child: CupertinoActivityIndicator())
                  : provider.resultadosManuales.isEmpty
                      ? const Center(
                          child: Text(
                            'Escriba un código o nombre para buscar',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.resultadosManuales.length,
                          itemBuilder: (context, indice) {
                            final Producto producto =
                                provider.resultadosManuales[indice];
                            return CupertinoListTile(
                              title: Text(producto.nombre),
                              subtitle: Text(
                                '${producto.codigo} · '
                                'Stock: ${producto.stock}',
                              ),
                              trailing: const Icon(
                                CupertinoIcons.chevron_right,
                                color: CupertinoColors.systemGrey,
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  CupertinoPageRoute<void>(
                                    builder: (_) => ProductoDetallePage(
                                      productoId: producto.id!,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
