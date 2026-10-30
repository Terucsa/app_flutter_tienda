import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/tema.dart';
import '../../domain/producto.dart';

/// Etiqueta del producto con código de barras Code 128 y código QR,
/// con opción de compartir/exportar como imagen para impresión.
class EtiquetaCodigosWidget extends StatefulWidget {
  const EtiquetaCodigosWidget({super.key, required this.producto});

  final Producto producto;

  @override
  State<EtiquetaCodigosWidget> createState() => _EtiquetaCodigosWidgetState();
}

class _EtiquetaCodigosWidgetState extends State<EtiquetaCodigosWidget> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _compartiendo = false;

  Future<void> _compartirEtiqueta() async {
    setState(() => _compartiendo = true);
    try {
      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final ui.Image imagen = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await imagen.toByteData(format: ui.ImageByteFormat.png);
      imagen.dispose();
      if (byteData == null) {
        throw Exception('No se pudo generar la imagen de la etiqueta.');
      }
      final Directory temporal = await getTemporaryDirectory();
      final File archivo = File(
        '${temporal.path}/etiqueta_${widget.producto.codigo}.png',
      );
      await archivo.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles([XFile(archivo.path)]);
    } catch (_) {
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('No se pudo exportar la etiqueta.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _compartiendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Producto producto = widget.producto;
    return Column(
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            color: CupertinoColors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  producto.nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Código: ${producto.codigo}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 12),
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: producto.codigo,
                  height: 60,
                  width: 240,
                  drawText: false,
                  color: CupertinoColors.black,
                ),
                const SizedBox(height: 16),
                BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: producto.codigo,
                  width: 120,
                  height: 120,
                  color: CupertinoColors.black,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          color: TemaApp.colorPrimario,
          borderRadius: BorderRadius.circular(10),
          onPressed: _compartiendo ? null : _compartirEtiqueta,
          child: _compartiendo
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CupertinoActivityIndicator(),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.share,
                      size: 18,
                      color: CupertinoColors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Compartir etiqueta',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
