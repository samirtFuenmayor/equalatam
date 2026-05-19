// lib/src/features/pedidos/presentation/widgets/pedido_form_sheet_impl.dart

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS Y CONSTANTES
// ═══════════════════════════════════════════════════════════════════════════════

enum CategoriaPedidoForm {
  FOUR_X_TWO, FOUR_X_FOUR, CARGA_GENERAL, DOCUMENTO;

  String get label => switch (this) {
    CategoriaPedidoForm.FOUR_X_TWO    => '4x2',
    CategoriaPedidoForm.FOUR_X_FOUR   => '4x4',
    CategoriaPedidoForm.CARGA_GENERAL => 'Carga General',
    CategoriaPedidoForm.DOCUMENTO     => 'Documento',
  };

  String get subtitle => switch (this) {
    CategoriaPedidoForm.FOUR_X_TWO    => 'Hasta 4.4 lb — Libre de impuestos',
    CategoriaPedidoForm.FOUR_X_FOUR   => 'Hasta 8.8 lb — Paga \$20 fijo si supera \$400',
    CategoriaPedidoForm.CARGA_GENERAL => 'Más de 8.8 lb — Arancel + IVA 15%',
    CategoriaPedidoForm.DOCUMENTO     => 'Solo documentos — Libre de impuestos',
  };

  String get categoriaPaquete => switch (this) {
    CategoriaPedidoForm.FOUR_X_TWO    => 'PEQUENO',
    CategoriaPedidoForm.FOUR_X_FOUR   => 'MEDIANO',
    CategoriaPedidoForm.CARGA_GENERAL => 'GRANDE',
    CategoriaPedidoForm.DOCUMENTO     => 'SOBRE',
  };

  // Peso máximo en libras (null = sin límite)
  double? get pesoMaxLb => switch (this) {
    CategoriaPedidoForm.FOUR_X_TWO    => 4.4,
    CategoriaPedidoForm.FOUR_X_FOUR   => 8.8,
    CategoriaPedidoForm.CARGA_GENERAL => null,
    CategoriaPedidoForm.DOCUMENTO     => 2.0,
  };

  IconData get icon => switch (this) {
    CategoriaPedidoForm.FOUR_X_TWO    => Icons.inventory_2_outlined,
    CategoriaPedidoForm.FOUR_X_FOUR   => Icons.inventory_outlined,
    CategoriaPedidoForm.CARGA_GENERAL => Icons.local_shipping_outlined,
    CategoriaPedidoForm.DOCUMENTO     => Icons.description_outlined,
  };
}

enum TipoProductoForm {
  ELECTRONICO, ROPA, COSMETICO, ALIMENTO,
  HERRAMIENTA, JUGUETE, LIBRO, DOCUMENTO, OTRO;

  String get label => switch (this) {
    TipoProductoForm.ELECTRONICO => 'Electrónico',
    TipoProductoForm.ROPA        => 'Ropa / Calzado',
    TipoProductoForm.COSMETICO   => 'Cosmético',
    TipoProductoForm.ALIMENTO    => 'Alimento / Suplemento',
    TipoProductoForm.HERRAMIENTA => 'Herramienta',
    TipoProductoForm.JUGUETE     => 'Juguete',
    TipoProductoForm.LIBRO       => 'Libro',
    TipoProductoForm.DOCUMENTO   => 'Documento',
    TipoProductoForm.OTRO        => 'Otro',
  };

  IconData get icon => switch (this) {
    TipoProductoForm.ELECTRONICO => Icons.devices_rounded,
    TipoProductoForm.ROPA        => Icons.checkroom_rounded,
    TipoProductoForm.COSMETICO   => Icons.face_rounded,
    TipoProductoForm.ALIMENTO    => Icons.restaurant_rounded,
    TipoProductoForm.HERRAMIENTA => Icons.build_rounded,
    TipoProductoForm.JUGUETE     => Icons.toys_rounded,
    TipoProductoForm.LIBRO       => Icons.menu_book_rounded,
    TipoProductoForm.DOCUMENTO   => Icons.description_rounded,
    TipoProductoForm.OTRO        => Icons.category_rounded,
  };

  List<String> get subcategorias => switch (this) {
    TipoProductoForm.ELECTRONICO => ['LAPTOP','CELULAR','TABLET','SMARTWATCH',
      'AURICULARES','CAMARA','CONSOLA_VIDEOJUEGOS','COMPONENTE_PC','OTRO_ELECTRONICO'],
    TipoProductoForm.ROPA => ['ROPA_HOMBRE','ROPA_MUJER','ROPA_NINO',
      'CALZADO','ACCESORIO_MODA','BOLSO_CARTERA','OTRO_TEXTIL'],
    TipoProductoForm.COSMETICO => ['PERFUME','CREMA_LOCION','MAQUILLAJE',
      'SUPLEMENTO_BELLEZA','OTRO_COSMETICO'],
    TipoProductoForm.ALIMENTO => ['SUPLEMENTO_DEPORTIVO','SNACK_GOLOSINA',
      'VITAMINA_MEDICAMENTO_OTC','OTRO_ALIMENTO'],
    TipoProductoForm.HERRAMIENTA => ['HERRAMIENTA_ELECTRICA','HERRAMIENTA_MANUAL',
      'REPUESTO_AUTOMOTRIZ','REPUESTO_INDUSTRIAL','OTRO_REPUESTO'],
    TipoProductoForm.JUGUETE => ['JUGUETE_INFANTIL','ARTICULO_BEBE',
      'JUEGO_MESA','FIGURA_COLECCIONABLE','OTRO_JUGUETE'],
    TipoProductoForm.LIBRO => ['LIBRO_TECNICO','LIBRO_TEXTO',
      'NOVELA_LITERATURA','REVISTA','OTRO_LIBRO'],
    TipoProductoForm.DOCUMENTO => ['DOCUMENTO_LEGAL','DOCUMENTO_ACADEMICO',
      'DOCUMENTO_COMERCIAL','OTRO_DOCUMENTO'],
    TipoProductoForm.OTRO => ['ARTICULO_HOGAR','DEPORTE_FITNESS',
      'MASCOTA_VETERINARIA','SIN_CLASIFICAR'],
  };

  String labelSubcategoria(String key) =>
      key.replaceAll('_', ' ').toLowerCase().split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO ITEM
// ═══════════════════════════════════════════════════════════════════════════════

class ItemFormData {
  TipoProductoForm tipo;
  String           subcategoria;
  String           descripcion;
  String           tracking;
  String           proveedor;
  String           peso;
  String           valorDeclarado;

  ItemFormData({
    this.tipo           = TipoProductoForm.ELECTRONICO,
    this.subcategoria   = '',
    this.descripcion    = '',
    this.tracking       = '',
    this.proveedor      = '',
    this.peso           = '',
    this.valorDeclarado = '',
  });

  double get pesoNum => double.tryParse(peso) ?? 0.0;

  Map<String, dynamic> toJson() => {
    'tipoProducto': tipo.name,
    'descripcion':  descripcion,
    if (subcategoria.isNotEmpty)   'subcategoria':    subcategoria,
    if (tracking.isNotEmpty)       'trackingExterno': tracking,
    if (proveedor.isNotEmpty)      'proveedor':       proveedor,
    if (peso.isNotEmpty)           'peso':            double.tryParse(peso),
    if (valorDeclarado.isNotEmpty) 'valorDeclarado':  double.tryParse(valorDeclarado),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHEET PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════

class PedidoFormSheet extends StatefulWidget {
  final String                clienteId;
  final VoidCallback          onCreado;
  final Map<String, dynamic>? clienteFijo;
  final String?               endpointOverride;

  const PedidoFormSheet({
    super.key,
    required this.clienteId,
    required this.onCreado,
    this.clienteFijo,
    this.endpointOverride,
  });

  @override
  State<PedidoFormSheet> createState() => _PedidoFormSheetState();
}

class _PedidoFormSheetState extends State<PedidoFormSheet>
    with SingleTickerProviderStateMixin {

  // ─── Paso actual (1–4) ────────────────────────────────────────────────────
  int _paso = 1;
  late final AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ─── Paso 1: Datos básicos ────────────────────────────────────────────────
  final _keyP1       = GlobalKey<FormState>();
  final _descCtrl    = TextEditingController();
  String               _tipo      = 'IMPORTACION';
  CategoriaPedidoForm  _categoria = CategoriaPedidoForm.FOUR_X_TWO;
  bool                 _cotizar   = true;
  String?              _origenId;
  String?              _destinoId;
  List<Map<String, String>> _sucursales = [];
  bool                 _loadingSuc = true;
  bool                 _loadingP1  = false;
  final List<ItemFormData> _items = [ItemFormData()];

  // ─── Paso 2 (cotización) ──────────────────────────────────────────────────
  Map<String, dynamic>? _cotizacion;
  String?               _cotizacionId;
  String?               _pedidoId;
  String?               _numeroPedido;

  // ─── Paso 3: Pago y facturación ───────────────────────────────────────────
  String _formaPago        = 'TRANSFERENCIA';
  bool   _usarDatosCliente = true;
  bool   _submittingP3     = false;
  final _bancoCtrl      = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _factRazonCtrl  = TextEditingController();
  final _factRucCtrl    = TextEditingController();
  final _factEmailCtrl  = TextEditingController();
  final _factTelCtrl    = TextEditingController();
  final _factDirCtrl    = TextEditingController();

  // ─── Paso 4: Comprobante ──────────────────────────────────────────────────
  String? _imagenBase64;
  String? _nombreArchivo;
  bool    _loadingImg   = false;
  bool    _submittingP4 = false;

  // ─── Helpers ──────────────────────────────────────────────────────────────
  bool get _esPresencial => widget.clienteFijo != null;

  double get _pesoTotal =>
      _items.fold(0.0, (s, i) => s + i.pesoNum);

  String get _endpoint =>
      widget.endpointOverride ?? '${ApiConstants.baseUrl}/api/pedidos';

  // Pasos totales: 4 si cotiza, 3 si no (sin paso de cotización)
  int get _totalPasos => 4;

  // Título por paso
  String get _tituloPaso => switch (_paso) {
    1 => 'Datos del pedido',
    2 => _cotizar ? 'Tu cotización' : 'Resumen del pedido',
    3 => 'Forma de pago',
    4 => 'Comprobante',
    _ => '',
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadSucursales();
    _initDatosPresencial();
  }

  void _initDatosPresencial() {
    if (!_esPresencial) return;
    final c = widget.clienteFijo!;
    _factRazonCtrl.text =
        '${c['nombres'] ?? ''} ${c['apellidos'] ?? ''}'.trim();
    _factRucCtrl.text =
        c['numeroIdentificacion']?.toString() ?? c['cedula']?.toString() ?? '';
    _factEmailCtrl.text = c['email']?.toString() ?? '';
    _factTelCtrl.text   = c['telefono']?.toString() ?? '';
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _descCtrl, _bancoCtrl, _referenciaCtrl,
      _factRazonCtrl, _factRucCtrl, _factEmailCtrl, _factTelCtrl, _factDirCtrl,
    ]) c.dispose();
    super.dispose();
  }

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Authorization': 'Bearer ${prefs.getString('eq_token') ?? ''}',
      'Content-Type':  'application/json',
    };
  }

  Future<void> _loadSucursales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/sucursales'),
          headers: {'Authorization': 'Bearer ${prefs.getString('eq_token') ?? ''}'});
      if (res.statusCode == 200 && mounted) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _sucursales = list.map((s) => {
            'id':     s['id'].toString(),
            'nombre': s['nombre'].toString(),
            'pais':   s['pais'].toString(),
          }).toList();
          _loadingSuc = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSuc = false);
    }
  }

  void _irPaso(int paso) {
    setState(() => _paso = paso);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _snackErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Validar peso vs categoría ────────────────────────────────────────────
  String? _validarPeso() {
    final max = _categoria.pesoMaxLb;
    if (max == null) return null; // CARGA_GENERAL sin límite
    if (_pesoTotal > max) {
      return 'El peso total (${_pesoTotal.toStringAsFixed(2)} lb) supera '
          'el máximo de ${max.toStringAsFixed(1)} lb para ${_categoria.label}.\n'
          'Selecciona otra categoría o reduce el peso.';
    }
    return null;
  }

  // ─── ACCIÓN PASO 1 ────────────────────────────────────────────────────────
  Future<void> _accionP1() async {
    if (!_keyP1.currentState!.validate()) return;
    if (_origenId == null || _destinoId == null) {
      _snackErr('Selecciona sucursal origen y destino'); return;
    }
    for (final item in _items) {
      if (item.descripcion.trim().isEmpty) {
        _snackErr('Todos los productos necesitan descripción'); return;
      }
    }
    final errPeso = _validarPeso();
    if (errPeso != null) { _snackErr(errPeso); return; }

    if (_cotizar) {
      // Crear pedido + cotización
      setState(() => _loadingP1 = true);
      try {
        final h   = await _authHeaders;
        final res = await http.post(
          Uri.parse(_endpoint),
          headers: h,
          body: jsonEncode(_buildBodyP1()),
        );
        if (!mounted) return;
        if (res.statusCode == 201) {
          final pedido  = jsonDecode(utf8.decode(res.bodyBytes));
          _pedidoId     = pedido['id']?.toString();
          _numeroPedido = pedido['numeroPedido']?.toString();

          // Cargar cotización generada
          if (_pedidoId != null) {
            final cotRes = await http.get(
              Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/pedido/$_pedidoId'),
              headers: h,
            );
            print('COT STATUS: ${cotRes.statusCode}');
            print('COT BODY: ${cotRes.body}');
            if (cotRes.statusCode == 200) {
              final decoded = jsonDecode(utf8.decode(cotRes.bodyBytes));
              final list = decoded as List;
              if (list.isNotEmpty) {
                _cotizacion   = list.first as Map<String, dynamic>;
                _cotizacionId = _cotizacion!['id']?.toString();
              } else {
                // Lista vacía — cotización existe en BD pero el endpoint no la retorna
                _snackErr('La cotización se creó pero no se pudo cargar. Intenta de nuevo.');
                setState(() => _loadingP1 = false);
                return;
              }
            } else {
              _snackErr('Error cargando cotización: ${cotRes.statusCode}');
              setState(() => _loadingP1 = false);
              return;
            }
          }
          setState(() => _loadingP1 = false);
          _irPaso(2);
        } else {
          String msg = 'Error al crear pedido';
          try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
          _snackErr(msg);
          setState(() => _loadingP1 = false);
        }
      } catch (_) {
        if (mounted) {
          _snackErr('Sin conexión al servidor');
          setState(() => _loadingP1 = false);
        }
      }
    } else {
      // Sin cotización: ir directo al resumen (paso 2 simplificado)
      _irPaso(2);
    }
  }

  Map<String, dynamic> _buildBodyP1() => {
    'tipo':               _tipo,
    'clienteId':          widget.clienteId,
    'descripcion':        _descCtrl.text.trim(),
    'sucursalOrigenId':   _origenId,
    'sucursalDestinoId':  _destinoId,
    'solicitaCotizacion': _cotizar,
    'categoriaPedido':    _categoria.name,
    'categoria':          _categoria.categoriaPaquete,
    'esPorTitular':       false,
    'items':              _items.map((i) => i.toJson()).toList(),
    if (_pesoTotal > 0)   'peso': _pesoTotal,
    'datosFacturacion':   {'usarDatosCliente': true},
  };

  // ─── ACCIÓN PASO 2 (cotización: aprobar/cancelar | sin cotización: continuar) ──
  void _accionP2Aprobar() => _irPaso(3);

  Future<void> _accionP2Cancelar() async {
    if (_cotizacionId == null && _pedidoId == null) {
      Navigator.pop(context); return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cancelar pedido?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Se eliminará el pedido y la cotización. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      if (_cotizacionId != null) {
        await http.delete(
          Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/$_cotizacionId/cancelar-cliente'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  // ─── ACCIÓN PASO 3 (confirmar pago) ──────────────────────────────────────
  Future<void> _accionP3() async {
    if (_formaPago == 'TRANSFERENCIA' && _bancoCtrl.text.trim().isEmpty) {
      _snackErr('Ingresa el banco de origen'); return;
    }
    setState(() => _submittingP3 = true);
    try {
      final h = await _authHeaders;

      if (_cotizar && _cotizacionId != null) {
        // Aprobar cotización con datos de pago
        final body = {
          'formaPago':        _formaPago,
          'bancoOrigen':      _bancoCtrl.text.trim(),
          'referenciaPago':   _referenciaCtrl.text.trim(),
          'datosFacturacion': _buildFactData(),
        };
        final res = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/$_cotizacionId/aprobar-cliente'),
          headers: h, body: jsonEncode(body),
        );
        if (!mounted) return;
        if (res.statusCode != 200) {
          String msg = 'Error al aprobar cotización';
          try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
          _snackErr(msg);
          setState(() => _submittingP3 = false);
          return;
        }
      } else if (!_cotizar) {
        // Crear pedido con datos de pago directamente
        final body = {
          ..._buildBodyP1(),
          'formaPago':         _formaPago,
          'bancoOrigen':       _bancoCtrl.text.trim(),
          'numeroReferencia':  _referenciaCtrl.text.trim(),
          'datosFacturacion':  _buildFactData(),
        };
        final res = await http.post(
          Uri.parse(_endpoint), headers: h, body: jsonEncode(body),
        );
        if (!mounted) return;
        if (res.statusCode == 201) {
          final pedido  = jsonDecode(utf8.decode(res.bodyBytes));
          _pedidoId     = pedido['id']?.toString();
          _numeroPedido = pedido['numeroPedido']?.toString();
        } else {
          String msg = 'Error al crear pedido';
          try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
          _snackErr(msg);
          setState(() => _submittingP3 = false);
          return;
        }
      }

      setState(() => _submittingP3 = false);
      _irPaso(4); // siempre va al comprobante después de confirmar pago
    } catch (_) {
      if (mounted) {
        _snackErr('Sin conexión al servidor');
        setState(() => _submittingP3 = false);
      }
    }
  }

  Map<String, dynamic> _buildFactData() => {
    'usarDatosCliente': _usarDatosCliente,
    if (!_usarDatosCliente) ...{
      'razonSocial':          _factRazonCtrl.text.trim(),
      'rucCedula':            _factRucCtrl.text.trim(),
      'emailFacturacion':     _factEmailCtrl.text.trim(),
      'telefonoFacturacion':  _factTelCtrl.text.trim(),
      'direccionFacturacion': _factDirCtrl.text.trim(),
    },
  };

  // ─── ACCIÓN PASO 4 (subir comprobante) ───────────────────────────────────
  Future<void> _seleccionarImagen() async {
    setState(() => _loadingImg = true);
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.image, allowMultiple: false, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _imagenBase64  = base64Encode(file.bytes!);
            _nombreArchivo = file.name;
          });
        }
      }
    } catch (e) { _snackErr('Error al seleccionar imagen: $e'); }
    if (mounted) setState(() => _loadingImg = false);
  }

  Future<void> _accionP4() async {
    if (_imagenBase64 == null) {
      _snackErr('Selecciona el comprobante de pago'); return;
    }
    if (_pedidoId == null) {
      _snackErr('Error: no se encontró el pedido. Vuelve al paso anterior.'); return;
    }
    setState(() => _submittingP4 = true);
    try {
      final h   = await _authHeaders;
      final body = {
        'comprobanteBase64': _imagenBase64,
        if (_bancoCtrl.text.trim().isNotEmpty) 'bancoOrigen': _bancoCtrl.text.trim(),
        if (_referenciaCtrl.text.trim().isNotEmpty) 'numeroReferencia': _referenciaCtrl.text.trim(),
      };
      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/pedidos/$_pedidoId/comprobante'),
        headers: h, body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context);
        widget.onCreado();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Pedido $_numeroPedido registrado correctamente.'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        String msg = 'Error al subir comprobante';
        try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
        _snackErr(msg);
      }
    } catch (_) { if (mounted) _snackErr('Sin conexión al servidor'); }
    if (mounted) setState(() => _submittingP4 = false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        Flexible(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // ── Header ──────────────────────────────────────────────────────
              Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_tituloPaso, style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
                  if (_numeroPedido != null)
                    Text(_numeroPedido!, style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                ])),
                if (_paso > 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => _irPaso(_paso - 1),
                    tooltip: 'Atrás',
                  ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),

              // ── Indicador de pasos ──────────────────────────────────────────
              PasoIndicador(pasoActual: _paso, total: _totalPasos, cotiza: _cotizar),
              const SizedBox(height: 24),

              // ── Contenido del paso ──────────────────────────────────────────
              switch (_paso) {
                1 => _buildPaso1(),
                2 => _cotizar ? _buildPaso2Cotizacion() : _buildPaso2Resumen(),
                3 => _buildPaso3Pago(),
                4 => _buildPaso4Comprobante(),
                _ => const SizedBox.shrink(),
              },
            ]),
          ),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 1 — DATOS DEL PEDIDO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaso1() => Form(
    key: _keyP1,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      // Banner cliente presencial
      if (_esPresencial) ...[
        _PresencialBanner(cliente: widget.clienteFijo!),
        const SizedBox(height: 16),
      ],

      // Tipo de envío
      _SectionLabel('Tipo de envío'),
      const SizedBox(height: 8),
      Row(children: ['IMPORTACION', 'EXPORTACION'].map((t) {
        final sel = _tipo == t;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: t == 'IMPORTACION' ? 6 : 0),
          child: _TipoCard(
            label:     t == 'IMPORTACION' ? 'Importación' : 'Exportación',
            icon:      t == 'IMPORTACION'
                ? Icons.flight_land_rounded : Icons.flight_takeoff_rounded,
            selected:  sel,
            onTap:     () => setState(() => _tipo = t),
          ),
        ));
      }).toList()),
      const SizedBox(height: 20),

      // Descripción
      _SectionLabel('Descripción general *'),
      const SizedBox(height: 8),
      TextFormField(
          controller: _descCtrl, maxLines: 2,
          decoration: _fDeco('Ej: Compras Amazon — ropa y electrónica'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null),
      const SizedBox(height: 20),

      // Categoría
      _SectionLabel('Categoría del paquete *'),
      const SizedBox(height: 4),
      // Aviso peso si hay items
      if (_pesoTotal > 0) ...[
        _PesoWarning(pesoTotal: _pesoTotal, categoria: _categoria),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      ...CategoriaPedidoForm.values.map((cat) => _CategoriaCard(
        cat: cat, selected: _categoria == cat,
        onTap: () => setState(() => _categoria = cat),
      )),
      const SizedBox(height: 16),

      // Toggle cotización
      _CotizarToggle(
          cotizar: _cotizar,
          onChanged: (v) => setState(() => _cotizar = v)),
      const SizedBox(height: 20),

      // Sucursales
      _SectionLabel('Sucursal origen *'),
      const SizedBox(height: 8),
      _loadingSuc
          ? const _LoadingDropdown()
          : FormSucDropdown(
          hint: 'Sede exterior donde llega el paquete',
          value: _origenId,
          sucursales: _sucursales,
          excluir: _destinoId,
          onChanged: (v) => setState(() => _origenId = v)),
      const SizedBox(height: 14),
      _SectionLabel('Sucursal destino *'),
      const SizedBox(height: 8),
      FormSucDropdown(
          hint: 'Sucursal en Ecuador donde retiras',
          value: _destinoId,
          sucursales: _sucursales,
          excluir: _origenId,
          onChanged: (v) => setState(() => _destinoId = v)),
      const SizedBox(height: 22),

      // Productos
      Row(children: [
        const Expanded(child: Text('Mis productos',
            style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 15, color: Color(0xFF1A1A2E)))),
        if (_pesoTotal > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${_pesoTotal.toStringAsFixed(2)} lb total',
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
          ),
      ]),
      const SizedBox(height: 12),

      ..._items.asMap().entries.map((e) => FormItemCard(
        index:     e.key,
        item:      _items[e.key],
        onChanged: () => setState(() {}),
        onRemove:  _items.length > 1
            ? () => setState(() => _items.removeAt(e.key)) : null,
      )),

      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => setState(() => _items.add(ItemFormData())),
        style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A237E),
            side: const BorderSide(color: Color(0xFF1A237E)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12)),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Agregar producto', style: TextStyle(fontSize: 13)),
      ),
      const SizedBox(height: 28),

      // Botón siguiente
      SizedBox(height: 52, child: ElevatedButton.icon(
        onPressed: _loadingP1 ? null : _accionP1,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
        icon: _loadingP1
            ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.arrow_forward_rounded, size: 20),
        label: Text(
            _loadingP1 ? 'Procesando...'
                : _cotizar ? 'Ver cotización →' : 'Ver resumen →',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      )),
    ]),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 2A — COTIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaso2Cotizacion() {
    if (_cotizacion == null) {
      return const Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF1A237E))));
    }

    final subtotal = ((_cotizacion!['subtotal'] as num?)?.toDouble() ?? 0);
    final iva      = ((_cotizacion!['montoIva'] as num?)?.toDouble() ?? 0);
    final total    = ((_cotizacion!['total'] as num?)?.toDouble() ?? 0);
    final pReal    = (_cotizacion!['pesoReal'] as num?)?.toDouble();
    final pFact    = (_cotizacion!['pesoFacturable'] as num?)?.toDouble();
    final detalle  = _cotizacion!['detalleCalculo']?.toString() ?? '';
    final validaHasta = _cotizacion!['validaHasta']?.toString() ?? '';

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      // Banner de éxito
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)]),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Cotización generada',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_cotizacion!['numeroCotizacion']?.toString() ?? '',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
          if (validaHasta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Válida hasta: $validaHasta',
                style: TextStyle(color: Colors.white.withOpacity(0.8),
                    fontSize: 11)),
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // Desglose
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: [
          if (pReal != null) _FilaCot('Peso real', '${pReal.toStringAsFixed(2)} lb'),
          if (pFact != null) _FilaCot('Peso facturable', '${pFact.toStringAsFixed(2)} lb'),
          if (detalle.isNotEmpty) ...[
            const Divider(height: 16),
            Text(detalle, style: const TextStyle(
                fontSize: 10, color: Color(0xFF6B7280))),
          ],
          const Divider(height: 16),
          _FilaCot('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          _FilaCot('IVA 15%', '\$${iva.toStringAsFixed(2)}'),
          const Divider(height: 12),
          Row(children: [
            const Text('TOTAL A PAGAR', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1A2E))),
            const Spacer(),
            Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF1A237E))),
          ]),
        ]),
      ),
      const SizedBox(height: 12),

      // Resumen de productos
      _ResumenProductos(items: _items, descripcion: _descCtrl.text.trim()),
      const SizedBox(height: 24),

      // Botones
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _accionP2Cancelar,
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(color: Color(0xFFC62828)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
        )),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 50, child: ElevatedButton.icon(
          onPressed: _accionP2Aprobar,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Aprobar y pagar →',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ))),
      ]),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 2B — RESUMEN (sin cotización)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaso2Resumen() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [

    // Banner informativo
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF90CAF9))),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF1565C0), size: 20),
        SizedBox(width: 10),
        Expanded(child: Text(
          'Pedido sin cotización previa. El equipo lo revisará '
              'y calculará el costo. Sube el comprobante de pago '
              'cuando esté listo.',
          style: TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
        )),
      ]),
    ),
    const SizedBox(height: 20),

    // Resumen del pedido
    _SectionLabel('Resumen del pedido'),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FilaCot('Tipo', _tipo == 'IMPORTACION' ? 'Importación' : 'Exportación'),
        _FilaCot('Categoría', _categoria.label),
        if (_pesoTotal > 0)
          _FilaCot('Peso total', '${_pesoTotal.toStringAsFixed(2)} lb'),
        _FilaCot('Productos', '${_items.length} producto${_items.length > 1 ? 's' : ''}'),
        const Divider(height: 16),
        Text(_descCtrl.text.trim(), style: const TextStyle(
            fontSize: 12, color: Color(0xFF6B7280))),
      ]),
    ),
    const SizedBox(height: 16),

    _ResumenProductos(items: _items, descripcion: _descCtrl.text.trim()),
    const SizedBox(height: 24),

    SizedBox(height: 52, child: ElevatedButton.icon(
      onPressed: () => _irPaso(3),
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
      label: const Text('Continuar al pago →',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    )),
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 3 — PAGO Y FACTURACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaso3Pago() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [

    _SectionLabel('Forma de pago'),
    const SizedBox(height: 10),
    Row(children: ['EFECTIVO', 'TRANSFERENCIA'].map((f) {
      final sel = _formaPago == f;
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: f == 'EFECTIVO' ? 6 : 0),
        child: GestureDetector(
          onTap: () => setState(() => _formaPago = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: sel ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? const Color(0xFF2E7D32) : const Color(0xFFE5E7EB),
                    width: sel ? 2 : 1)),
            child: Column(children: [
              Icon(f == 'EFECTIVO'
                  ? Icons.payments_outlined : Icons.account_balance_outlined,
                  color: sel ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
                  size: 24),
              const SizedBox(height: 6),
              Text(f == 'EFECTIVO' ? 'Efectivo' : 'Transferencia',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: sel ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF))),
            ]),
          ),
        ),
      ));
    }).toList()),
    const SizedBox(height: 14),

    // Campos bancarios si es transferencia
    if (_formaPago == 'TRANSFERENCIA') ...[
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Expanded(child: Text(
            'En el siguiente paso subirás el comprobante de transferencia.',
            style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextFormField(
            controller: _bancoCtrl,
            decoration: _fDeco('Banco origen *'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(
            controller: _referenciaCtrl,
            decoration: _fDeco('Referencia (opcional)'))),
      ]),
      const SizedBox(height: 20),
    ] else ...[
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Expanded(child: Text(
            'En el siguiente paso subirás la foto del recibo de efectivo.',
            style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
          )),
        ]),
      ),
      const SizedBox(height: 20),
    ],

    // Facturación
    _SectionLabel('Datos de facturación'),
    const SizedBox(height: 10),
    GestureDetector(
      onTap: () => setState(() => _usarDatosCliente = !_usarDatosCliente),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: _usarDatosCliente ? const Color(0xFFE8EAF6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _usarDatosCliente ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB),
                width: _usarDatosCliente ? 2 : 1)),
        child: Row(children: [
          Icon(_usarDatosCliente
              ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: _usarDatosCliente ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF),
              size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_esPresencial ? 'Usar datos del cliente' : 'Usar mis datos personales',
                style: const TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 13, color: Color(0xFF374151))),
            const Text('Nombre, cédula y correo registrados',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),
        ]),
      ),
    ),

    if (!_usarDatosCliente) ...[
      const SizedBox(height: 12),
      TextFormField(controller: _factRazonCtrl,
          decoration: _fDeco('Razón social o nombre')),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(controller: _factRucCtrl,
            decoration: _fDeco('RUC / Cédula'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(controller: _factTelCtrl,
            decoration: _fDeco('Teléfono'))),
      ]),
      const SizedBox(height: 8),
      TextFormField(controller: _factEmailCtrl,
          decoration: _fDeco('Correo electrónico')),
      const SizedBox(height: 8),
      TextFormField(controller: _factDirCtrl,
          decoration: _fDeco('Dirección')),
    ],
    const SizedBox(height: 28),

    SizedBox(height: 52, child: ElevatedButton.icon(
      onPressed: _submittingP3 ? null : _accionP3,
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      icon: _submittingP3
          ? const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.arrow_forward_rounded, size: 20),
      label: Text(_submittingP3 ? 'Procesando...' : 'Confirmar y subir comprobante →',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    )),
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 4 — COMPROBANTE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaso4Comprobante() {
    final esTransferencia = _formaPago == 'TRANSFERENCIA';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      // Confirmación pedido creado
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0))),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pedido $_numeroPedido creado ✓',
                style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 13, color: Color(0xFF2E7D32))),
            const Text('Ahora sube el comprobante de pago',
                style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
          ])),
        ]),
      ),
      const SizedBox(height: 20),

      _SectionLabel(esTransferencia
          ? 'Comprobante de transferencia' : 'Foto del recibo'),
      const SizedBox(height: 12),

      // Selector de imagen
      GestureDetector(
        onTap: _loadingImg ? null : _seleccionarImagen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _imagenBase64 != null ? null : 160,
          decoration: BoxDecoration(
              color: _imagenBase64 != null ? Colors.transparent : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _imagenBase64 != null
                      ? const Color(0xFF2E7D32) : const Color(0xFFE5E7EB),
                  width: _imagenBase64 != null ? 2 : 1)),
          child: _loadingImg
              ? const Center(child: Padding(padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF1A237E))))
              : _imagenBase64 != null
              ? _ImagenPreviewWidget(
              base64: _imagenBase64!,
              nombre: _nombreArchivo ?? 'comprobante',
              onCambiar: _seleccionarImagen)
              : _SelectorVacio(esTransferencia: esTransferencia),
        ),
      ),
      const SizedBox(height: 28),

      SizedBox(height: 52, child: ElevatedButton.icon(
        onPressed: _submittingP4 ? null : _accionP4,
        style: ElevatedButton.styleFrom(
            backgroundColor: _imagenBase64 != null
                ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        icon: _submittingP4
            ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.upload_rounded, size: 20),
        label: Text(
            _submittingP4 ? 'Enviando...'
                : _imagenBase64 != null ? 'Enviar comprobante ✓'
                : 'Selecciona una imagen primero',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS PÚBLICOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Indicador de pasos con labels dinámicos según flujo
class PasoIndicador extends StatelessWidget {
  final int  pasoActual, total;
  final bool cotiza;
  const PasoIndicador({super.key,
    required this.pasoActual, required this.total, required this.cotiza});

  @override
  Widget build(BuildContext context) {
    final labels = cotiza
        ? ['Datos', 'Cotización', 'Pago', 'Comprobante']
        : ['Datos', 'Resumen', 'Pago'];

    return Row(children: List.generate(total, (i) {
      final activo   = i + 1 == pasoActual;
      final completo = i + 1 < pasoActual;
      return Expanded(child: Row(children: [
        Expanded(child: Column(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completo ? const Color(0xFF2E7D32)
                    : activo ? const Color(0xFF1A237E)
                    : const Color(0xFFE5E7EB)),
            child: Center(child: completo
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text('${i + 1}', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: activo ? Colors.white : const Color(0xFF9CA3AF)))),
          ),
          const SizedBox(height: 4),
          Text(labels[i], style: TextStyle(fontSize: 9,
              fontWeight: FontWeight.w600,
              color: activo ? const Color(0xFF1A237E)
                  : completo ? const Color(0xFF2E7D32)
                  : const Color(0xFF9CA3AF))),
        ])),
        if (i < total - 1)
          Expanded(child: Container(height: 2,
              color: completo ? const Color(0xFF2E7D32) : const Color(0xFFE5E7EB))),
      ]));
    }));
  }
}

class FormSucDropdown extends StatelessWidget {
  final String                    hint;
  final String?                   value, excluir;
  final List<Map<String, String>> sucursales;
  final void Function(String?)    onChanged;

  const FormSucDropdown({super.key,
    required this.hint, required this.value,
    required this.sucursales, required this.onChanged, this.excluir});

  @override
  Widget build(BuildContext context) {
    final items = sucursales.where((s) => s['id'] != excluir).toList();
    final cur   = (value != null && items.any((s) => s['id'] == value)) ? value : null;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: cur,
            hint: Text(hint, style: const TextStyle(
                color: Color(0xFF9CA3AF), fontSize: 13)),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: items.map((s) => DropdownMenuItem(
                value: s['id'],
                child: Text('${s['nombre']} (${s['pais']})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged)));
  }
}

class FormItemCard extends StatefulWidget {
  final int           index;
  final ItemFormData  item;
  final VoidCallback  onChanged;
  final VoidCallback? onRemove;

  const FormItemCard({super.key,
    required this.index, required this.item,
    required this.onChanged, this.onRemove});

  @override
  State<FormItemCard> createState() => _FormItemCardState();
}

class _FormItemCardState extends State<FormItemCard> {
  late final TextEditingController _descCtrl, _trackCtrl,
      _provCtrl, _pesoCtrl, _valorCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl  = TextEditingController(text: widget.item.descripcion);
    _trackCtrl = TextEditingController(text: widget.item.tracking);
    _provCtrl  = TextEditingController(text: widget.item.proveedor);
    _pesoCtrl  = TextEditingController(text: widget.item.peso);
    _valorCtrl = TextEditingController(text: widget.item.valorDeclarado);
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _trackCtrl, _provCtrl, _pesoCtrl, _valorCtrl])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Row(children: [
          Container(width: 24, height: 24,
              decoration: BoxDecoration(color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text('${widget.index + 1}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 8),
          const Text('Producto', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13,
              color: Color(0xFF374151))),
          const Spacer(),
          if (widget.onRemove != null)
            IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded,
                    color: Color(0xFFC62828), size: 20),
                onPressed: widget.onRemove, padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<TipoProductoForm>(
                  value: widget.item.tipo, isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  items: TipoProductoForm.values.map((t) => DropdownMenuItem(
                      value: t, child: Row(children: [
                    Icon(t.icon, size: 16, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(t.label, style: const TextStyle(fontSize: 13)),
                  ]))).toList(),
                  onChanged: (v) {
                    widget.item.tipo         = v!;
                    widget.item.subcategoria = '';
                    widget.onChanged();
                  },
                )),
          ),
          const SizedBox(height: 8),
          // Subcategoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: widget.item.subcategoria.isNotEmpty
                  ? widget.item.subcategoria : null,
              hint: const Text('Subcategoría (opcional)',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              items: widget.item.tipo.subcategorias.map((s) =>
                  DropdownMenuItem(value: s, child: Text(
                    widget.item.tipo.labelSubcategoria(s),
                    style: const TextStyle(fontSize: 13),
                  ))).toList(),
              onChanged: (v) {
                widget.item.subcategoria = v ?? '';
                widget.onChanged();
              },
            )),
          ),
          const SizedBox(height: 8),
          TextFormField(controller: _descCtrl,
              decoration: _fDeco('Descripción del producto *'),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) { widget.item.descripcion = v; widget.onChanged(); }),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(controller: _trackCtrl,
                decoration: _fDeco('Tracking (opcional)'),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) { widget.item.tracking = v; widget.onChanged(); })),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _provCtrl,
                decoration: _fDeco('Proveedor'),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) { widget.item.proveedor = v; widget.onChanged(); })),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(controller: _pesoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fDeco('Peso (lb)'),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) { widget.item.peso = v; widget.onChanged(); })),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fDeco('Valor USD'),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) { widget.item.valorDeclarado = v; widget.onChanged(); })),
          ]),
        ]),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS DE APOYO
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Color(0xFF374151)));
}

class _TipoCard extends StatelessWidget {
  final String label; final IconData icon;
  final bool selected; final VoidCallback onTap;
  const _TipoCard({required this.label, required this.icon,
    required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8EAF6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1)),
      child: Column(children: [
        Icon(icon, color: selected ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF),
            size: 22),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF))),
      ]),
    ),
  );
}

class _CategoriaCard extends StatelessWidget {
  final CategoriaPedidoForm cat;
  final bool selected;
  final VoidCallback onTap;
  const _CategoriaCard({required this.cat, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8EAF6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1)),
      child: Row(children: [
        Container(width: 20, height: 20,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF1A237E) : Colors.white,
                border: Border.all(
                    color: selected ? const Color(0xFF1A237E) : const Color(0xFFD1D5DB),
                    width: 2)),
            child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
        const SizedBox(width: 10),
        Icon(cat.icon,
            color: selected ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF),
            size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cat.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF1A237E) : const Color(0xFF374151))),
          Text(cat.subtitle, style: const TextStyle(
              fontSize: 11, color: Color(0xFF6B7280))),
        ])),
        if (cat.pesoMaxLb != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: selected ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8)),
            child: Text('≤ ${cat.pesoMaxLb}lb',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF6B7280))),
          ),
      ]),
    ),
  );
}

class _PesoWarning extends StatelessWidget {
  final double pesoTotal;
  final CategoriaPedidoForm categoria;
  const _PesoWarning({required this.pesoTotal, required this.categoria});

  @override
  Widget build(BuildContext context) {
    final max = categoria.pesoMaxLb;
    if (max == null) return const SizedBox.shrink();
    final excede = pesoTotal > max;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: excede ? const Color(0xFFFFEBEE) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: excede ? const Color(0xFFC62828) : const Color(0xFFBBF7D0))),
      child: Row(children: [
        Icon(excede ? Icons.warning_rounded : Icons.check_circle_outline,
            size: 16,
            color: excede ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(child: Text(
          excede
              ? '⚠ ${pesoTotal.toStringAsFixed(2)} lb excede el máximo de ${max}lb para ${categoria.label}'
              : '✓ ${pesoTotal.toStringAsFixed(2)} lb — dentro del límite de ${max}lb',
          style: TextStyle(fontSize: 11,
              color: excede ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
        )),
      ]),
    );
  }
}

class _CotizarToggle extends StatelessWidget {
  final bool cotizar;
  final ValueChanged<bool> onChanged;
  const _CotizarToggle({required this.cotizar, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!cotizar),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cotizar ? const Color(0xFFE8EAF6) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: cotizar ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB))),
      child: Row(children: [
        Icon(cotizar ? Icons.calculate_outlined : Icons.send_outlined,
            color: cotizar ? const Color(0xFF1A237E) : const Color(0xFF6B7280), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cotizar ? 'Quiero cotización primero' : 'Enviar sin cotizar',
              style: const TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 13, color: Color(0xFF374151))),
          Text(cotizar
              ? 'Verás el precio exacto antes de pagar'
              : 'El equipo procesará y calculará el costo',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ])),
        Switch(value: cotizar, onChanged: onChanged, activeColor: const Color(0xFF1A237E)),
      ]),
    ),
  );
}

class _PresencialBanner extends StatelessWidget {
  final Map<String, dynamic> cliente;
  const _PresencialBanner({required this.cliente});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC5CAE9))),
    child: Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${cliente['nombres'] ?? ''} ${cliente['apellidos'] ?? ''}'.trim(),
            style: const TextStyle(fontWeight: FontWeight.w700,
                fontSize: 13, color: Color(0xFF1A1A2E))),
        Text('Casillero: ${cliente['casillero'] ?? ''}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF3949AB))),
      ])),
    ]),
  );
}

class _ResumenProductos extends StatelessWidget {
  final List<ItemFormData> items;
  final String descripcion;
  const _ResumenProductos({required this.items, required this.descripcion});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$descripcion', style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const Divider(height: 14),
      ...items.map((i) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(i.tipo.icon, size: 14, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(child: Text(
              i.descripcion.isNotEmpty ? i.descripcion : '(sin descripción)',
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
          if (i.pesoNum > 0)
            Text('${i.pesoNum.toStringAsFixed(2)} lb',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
      )),
    ]),
  );
}

class _FilaCot extends StatelessWidget {
  final String label, value;
  const _FilaCot(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: Color(0xFF374151))),
    ]),
  );
}

class _LoadingDropdown extends StatelessWidget {
  const _LoadingDropdown();
  @override
  Widget build(BuildContext context) => Container(
    height: 52, padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: const Row(children: [
      SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A237E))),
      SizedBox(width: 12),
      Text('Cargando sucursales...', style: TextStyle(
          fontSize: 13, color: Color(0xFF9CA3AF))),
    ]),
  );
}

class _ImagenPreviewWidget extends StatelessWidget {
  final String base64, nombre;
  final VoidCallback onCambiar;
  const _ImagenPreviewWidget({required this.base64, required this.nombre, required this.onCambiar});

  @override
  Widget build(BuildContext context) => Column(children: [
    ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Image.memory(base64Decode(base64),
          width: double.infinity, height: 200, fit: BoxFit.cover),
    ),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFFF0FDF4),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(nombre, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600))),
        TextButton(onPressed: onCambiar,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text('Cambiar',
                style: TextStyle(fontSize: 11, color: Color(0xFF1A237E)))),
      ]),
    ),
  ]);
}

class _SelectorVacio extends StatelessWidget {
  final bool esTransferencia;
  const _SelectorVacio({required this.esTransferencia});
  @override
  Widget build(BuildContext context) => Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(color: Color(0xFFE8EAF6), shape: BoxShape.circle),
        child: Icon(esTransferencia ? Icons.receipt_long_outlined : Icons.camera_alt_outlined,
            size: 28, color: const Color(0xFF1A237E))),
    const SizedBox(height: 10),
    const Text('Toca para seleccionar', style: TextStyle(
        fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
    const SizedBox(height: 4),
    const Text('JPG o PNG desde tu galería',
        style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
  ]);
}

// ─── Helpers globales ────────────────────────────────────────────────────────

InputDecoration _fDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFC62828))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFC62828), width: 2)),
);