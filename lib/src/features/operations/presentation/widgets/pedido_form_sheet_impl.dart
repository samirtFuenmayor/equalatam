// lib/src/features/pedidos/presentation/widgets/pedido_form_sheet_impl.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum CategoriaPedidoForm {
  FOUR_X_TWO, FOUR_X_FOUR, CARGA_GENERAL, DOCUMENTO;

  String get label => switch (this) {
    CategoriaPedidoForm.FOUR_X_TWO    => '4x2 (hasta 4.4 lb)',
    CategoriaPedidoForm.FOUR_X_FOUR   => '4x4 (hasta 8.8 lb)',
    CategoriaPedidoForm.CARGA_GENERAL => 'Carga General',
    CategoriaPedidoForm.DOCUMENTO     => 'Documento',
  };

  String get description => switch (this) {
    CategoriaPedidoForm.FOUR_X_TWO    => 'Libre de impuestos',
    CategoriaPedidoForm.FOUR_X_FOUR   => 'Hasta \$400 — paga \$20 fijo',
    CategoriaPedidoForm.CARGA_GENERAL => 'Arancel + IVA 15%',
    CategoriaPedidoForm.DOCUMENTO     => 'Solo documentos — libre',
  };

  String get categoriaPaquete => switch (this) {
    CategoriaPedidoForm.FOUR_X_TWO    => 'PEQUENO',
    CategoriaPedidoForm.FOUR_X_FOUR   => 'MEDIANO',
    CategoriaPedidoForm.CARGA_GENERAL => 'GRANDE',
    CategoriaPedidoForm.DOCUMENTO     => 'SOBRE',
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
    TipoProductoForm.ELECTRONICO => [
      'LAPTOP','CELULAR','TABLET','SMARTWATCH','AURICULARES',
      'CAMARA','CONSOLA_VIDEOJUEGOS','COMPONENTE_PC','OTRO_ELECTRONICO'
    ],
    TipoProductoForm.ROPA => [
      'ROPA_HOMBRE','ROPA_MUJER','ROPA_NINO',
      'CALZADO','ACCESORIO_MODA','BOLSO_CARTERA','OTRO_TEXTIL'
    ],
    TipoProductoForm.COSMETICO => [
      'PERFUME','CREMA_LOCION','MAQUILLAJE',
      'SUPLEMENTO_BELLEZA','OTRO_COSMETICO'
    ],
    TipoProductoForm.ALIMENTO => [
      'SUPLEMENTO_DEPORTIVO','SNACK_GOLOSINA',
      'VITAMINA_MEDICAMENTO_OTC','OTRO_ALIMENTO'
    ],
    TipoProductoForm.HERRAMIENTA => [
      'HERRAMIENTA_ELECTRICA','HERRAMIENTA_MANUAL',
      'REPUESTO_AUTOMOTRIZ','REPUESTO_INDUSTRIAL','OTRO_REPUESTO'
    ],
    TipoProductoForm.JUGUETE => [
      'JUGUETE_INFANTIL','ARTICULO_BEBE',
      'JUEGO_MESA','FIGURA_COLECCIONABLE','OTRO_JUGUETE'
    ],
    TipoProductoForm.LIBRO => [
      'LIBRO_TECNICO','LIBRO_TEXTO',
      'NOVELA_LITERATURA','REVISTA','OTRO_LIBRO'
    ],
    TipoProductoForm.DOCUMENTO => [
      'DOCUMENTO_LEGAL','DOCUMENTO_ACADEMICO',
      'DOCUMENTO_COMERCIAL','OTRO_DOCUMENTO'
    ],
    TipoProductoForm.OTRO => [
      'ARTICULO_HOGAR','DEPORTE_FITNESS',
      'MASCOTA_VETERINARIA','SIN_CLASIFICAR'
    ],
  };

  String labelSubcategoria(String key) =>
      key.replaceAll('_', ' ').toLowerCase().split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
}

// ─── Modelo de item del formulario ───────────────────────────────────────────

class ItemFormData {
  TipoProductoForm tipo;
  String           subcategoria;
  String           descripcion;
  String           tracking;
  String           proveedor;
  String           peso;
  String           valorDeclarado;

  ItemFormData({
    this.tipo          = TipoProductoForm.ELECTRONICO,
    this.subcategoria  = '',
    this.descripcion   = '',
    this.tracking      = '',
    this.proveedor     = '',
    this.peso          = '',
    this.valorDeclarado= '',
  });

  Map<String, dynamic> toJson() => {
    'tipoProducto': tipo.name,
    'descripcion':  descripcion,
    if (subcategoria.isNotEmpty)    'subcategoria':    subcategoria,
    if (tracking.isNotEmpty)        'trackingExterno': tracking,
    if (proveedor.isNotEmpty)       'proveedor':       proveedor,
    if (peso.isNotEmpty)            'peso':            double.tryParse(peso),
    if (valorDeclarado.isNotEmpty)  'valorDeclarado':  double.tryParse(valorDeclarado),
  };
}

// ─── Sheet principal: 3 pasos ─────────────────────────────────────────────────

class PedidoFormSheet extends StatefulWidget {
  final String                clienteId;
  final VoidCallback          onCreado;
  /// Si viene con clienteFijo es flujo presencial (admin/agente)
  final Map<String, dynamic>? clienteFijo;
  /// Endpoint a usar: /api/pedidos o /api/pedidos/sucursal
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

class _PedidoFormSheetState extends State<PedidoFormSheet> {

  // ─── Paso ─────────────────────────────────────────────────────────────────
  int _paso = 1;

  // ─── Paso 1 ───────────────────────────────────────────────────────────────
  final _keyP1    = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String              _tipo      = 'IMPORTACION';
  CategoriaPedidoForm _categoria = CategoriaPedidoForm.FOUR_X_TWO;
  bool                _cotizar   = true;
  String?             _origenId;
  String?             _destinoId;
  List<Map<String, String>> _sucursales = [];
  bool                _loadingSuc = true;
  bool                _loadingCot = false;
  final List<ItemFormData> _items = [ItemFormData()];

  // ─── Paso 2 ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? _cotizacion;
  String  _formaPago        = 'TRANSFERENCIA';
  bool    _usarDatosCliente = true;
  bool    _submitting       = false;
  final _factRazonCtrl     = TextEditingController();
  final _factRucCtrl       = TextEditingController();
  final _factEmailCtrl     = TextEditingController();
  final _factTelefonoCtrl  = TextEditingController();
  final _factDireccionCtrl = TextEditingController();
  final _bancoCtrl         = TextEditingController();
  final _referenciaCtrl    = TextEditingController();

  // ─── Paso 3 ───────────────────────────────────────────────────────────────
  String? _pedidoId;
  String? _numeroPedido;
  String? _cotizacionId;
  String? _imagenBase64;
  String? _nombreArchivo;
  bool    _loadingImg = false;

  // ─── Helpers ──────────────────────────────────────────────────────────────
  bool get _esPresencial => widget.clienteFijo != null;

  double get _pesoTotal =>
      _items.fold(0.0, (s, i) => s + (double.tryParse(i.peso) ?? 0.0));

  String get _endpoint =>
      widget.endpointOverride ??
          '${ApiConstants.baseUrl}/api/pedidos';

  @override
  void initState() {
    super.initState();
    _loadSucursales();
    if (_esPresencial) {
      final c = widget.clienteFijo!;
      _factRazonCtrl.text =
          '${c['nombres'] ?? ''} ${c['apellidos'] ?? ''}'.trim();
      _factRucCtrl.text =
          c['numeroIdentificacion']?.toString() ??
              c['cedula']?.toString() ?? '';
      _factEmailCtrl.text    = c['email']?.toString() ?? '';
      _factTelefonoCtrl.text = c['telefono']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _factRazonCtrl.dispose();
    _factRucCtrl.dispose();
    _factEmailCtrl.dispose();
    _factTelefonoCtrl.dispose();
    _factDireccionCtrl.dispose();
    _bancoCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('eq_token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type':  'application/json',
    };
  }

  Future<void> _loadSucursales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res   = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/sucursales'),
          headers: {'Authorization': 'Bearer $token'});
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

  Map<String, dynamic> _buildBody() => {
    'tipo':               _tipo,
    'clienteId':          widget.clienteId,
    'descripcion':        _descCtrl.text.trim(),
    'sucursalOrigenId':   _origenId,
    'sucursalDestinoId':  _destinoId,
    'solicitaCotizacion': _cotizar,
    'categoriaPedido':    _categoria.name,          // ← FOUR_X_TWO, FOUR_X_FOUR...
    'categoria':          _categoria.categoriaPaquete, // ← PEQUENO, MEDIANO... (financiero)
    'esPorTitular':       false,
    'formaPago':          _formaPago,
    'items':              _items.map((i) => i.toJson()).toList(),
    if (_pesoTotal > 0) 'peso': _pesoTotal,
    'datosFacturacion':   {'usarDatosCliente': true},
  };

  Map<String, dynamic> _buildFactData() => {
    'usarDatosCliente':    _usarDatosCliente,
    if (!_usarDatosCliente) ...{
      'razonSocial':          _factRazonCtrl.text.trim(),
      'rucCedula':            _factRucCtrl.text.trim(),
      'emailFacturacion':     _factEmailCtrl.text.trim(),
      'telefonoFacturacion':  _factTelefonoCtrl.text.trim(),
      'direccionFacturacion': _factDireccionCtrl.text.trim(),
    },
  };

  void _snackErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Ir a paso 2 ─────────────────────────────────────────────────────────
  Future<void> _irPaso2() async {
    if (!_keyP1.currentState!.validate()) return;
    if (_origenId == null || _destinoId == null) {
      _snackErr('Selecciona sucursal origen y destino'); return;
    }
    for (final item in _items) {
      if (item.descripcion.trim().isEmpty) {
        _snackErr('Todos los productos deben tener descripción'); return;
      }
    }

    if (_cotizar) {
      setState(() => _loadingCot = true);
      try {
        final h   = await _headers;
        final res = await http.post(
          Uri.parse(_endpoint),
          headers: h,
          body: jsonEncode(_buildBody()),
        );
        if (!mounted) return;
        if (res.statusCode == 201) {
          final pedido  = jsonDecode(utf8.decode(res.bodyBytes));
          _pedidoId     = pedido['id']?.toString();
          _numeroPedido = pedido['numeroPedido']?.toString();

          // Cargar cotización
          if (_pedidoId != null) {
            final cotRes = await http.get(
              Uri.parse(
                  '${ApiConstants.baseUrl}/api/financiero/cotizaciones/pedido/$_pedidoId'),
              headers: h,
            );
            if (cotRes.statusCode == 200) {
              final list =
              jsonDecode(utf8.decode(cotRes.bodyBytes)) as List;
              if (list.isNotEmpty) {
                _cotizacion   = list.first as Map<String, dynamic>;
                _cotizacionId = _cotizacion!['id']?.toString();
              }
            }
          }
          setState(() { _paso = 2; _loadingCot = false; });
        } else {
          String msg = 'Error al crear el pedido';
          try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
          _snackErr(msg);
          setState(() => _loadingCot = false);
        }
      } catch (_) {
        if (mounted) {
          _snackErr('Sin conexión al servidor');
          setState(() => _loadingCot = false);
        }
      }
    } else {
      setState(() => _paso = 2);
    }
  }

  // ─── Confirmar pago ───────────────────────────────────────────────────────
  Future<void> _confirmarPago() async {
    if (_formaPago == 'TRANSFERENCIA' && _bancoCtrl.text.trim().isEmpty) {
      _snackErr('Ingresa el banco de origen'); return;
    }
    setState(() => _submitting = true);
    try {
      final h = await _headers;

      if (_cotizar && _cotizacionId != null) {
        final body = {
          'formaPago':        _formaPago,
          'bancoOrigen':      _bancoCtrl.text.trim(),
          'referenciaPago':   _referenciaCtrl.text.trim(),
          'datosFacturacion': _buildFactData(),
        };
        final res = await http.post(
          Uri.parse(
              '${ApiConstants.baseUrl}/api/financiero/cotizaciones/$_cotizacionId/aprobar-cliente'),
          headers: h,
          body: jsonEncode(body),
        );
        if (!mounted) return;
        if (res.statusCode != 200) {
          String msg = 'Error al aprobar cotización';
          try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
          _snackErr(msg);
          setState(() => _submitting = false);
          return;
        }
      } else if (!_cotizar) {
        final body = _buildBody()
          ..['formaPago']        = _formaPago
          ..['bancoOrigen']      = _bancoCtrl.text.trim()
          ..['numeroReferencia'] = _referenciaCtrl.text.trim()
          ..['datosFacturacion'] = _buildFactData();

        final res = await http.post(
          Uri.parse(_endpoint),
          headers: h,
          body: jsonEncode(body),
        );
        if (!mounted) return;
        if (res.statusCode == 201) {
          final pedido  = jsonDecode(utf8.decode(res.bodyBytes));
          _pedidoId     = pedido['id']?.toString();
          _numeroPedido = pedido['numeroPedido']?.toString();
        } else {
          String msg = 'Error al crear el pedido';
          try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
          _snackErr(msg);
          setState(() => _submitting = false);
          return;
        }
      }

      setState(() { _paso = 3; _submitting = false; });
    } catch (_) {
      if (mounted) {
        _snackErr('Sin conexión al servidor');
        setState(() => _submitting = false);
      }
    }
  }

  // ─── Cancelar cotización ──────────────────────────────────────────────────
  Future<void> _cancelarCotizacion() async {
    if (_cotizacionId == null && _pedidoId == null) {
      Navigator.pop(context); return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cancelar pedido?'),
        content: const Text(
            'Se eliminará el pedido y la cotización generada. '
                'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white),
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
          Uri.parse(
              '${ApiConstants.baseUrl}/api/financiero/cotizaciones/$_cotizacionId/cancelar-cliente'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  // ─── Seleccionar imagen ───────────────────────────────────────────────────
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
    } catch (e) {
      _snackErr('Error al seleccionar imagen: $e');
    }
    if (mounted) setState(() => _loadingImg = false);
  }

  // ─── Subir comprobante ────────────────────────────────────────────────────
  Future<void> _subirComprobante() async {
    if (_imagenBase64 == null) {
      _snackErr('Selecciona una imagen del comprobante'); return;
    }
    setState(() => _submitting = true);
    try {
      final h   = await _headers;
      final body = <String, dynamic>{
        'comprobanteBase64': _imagenBase64,
        if (_bancoCtrl.text.trim().isNotEmpty)
          'bancoOrigen': _bancoCtrl.text.trim(),
        if (_referenciaCtrl.text.trim().isNotEmpty)
          'numeroReferencia': _referenciaCtrl.text.trim(),
      };
      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/pedidos/$_pedidoId/comprobante'),
        headers: h,
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context);
        widget.onCreado();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '✅ Pedido $_numeroPedido registrado. '
                  'Comprobante enviado, pendiente verificación.'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        String msg = 'Error al subir comprobante';
        try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
        _snackErr(msg);
      }
    } catch (_) {
      if (mounted) _snackErr('Sin conexión al servidor');
    }
    if (mounted) setState(() => _submitting = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        Flexible(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(children: [
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_titulosPaso[_paso - 1],
                            style: const TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E))),
                        if (_paso > 1 && _numeroPedido != null)
                          Text(_numeroPedido!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280))),
                      ])),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 18),
                // Contenido por paso
                switch (_paso) {
                  1 => _buildPaso1(),
                  2 => _buildPaso2(),
                  3 => _buildPaso3(),
                  _ => const SizedBox.shrink(),
                },
              ]),
        )),
      ]),
    );
  }

  static const _titulosPaso = [
    'Nuevo Pedido',
    'Confirmar y pagar',
    'Comprobante de pago',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 1
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPaso1() => Form(
    key: _keyP1,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      PasoIndicador(pasoActual: 1, total: 3),
      const SizedBox(height: 20),

      // Banner cliente fijo (presencial)
      if (_esPresencial) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC5CAE9))),
          child: Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A237E),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${widget.clienteFijo!['nombres'] ?? ''} '
                          '${widget.clienteFijo!['apellidos'] ?? ''}'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 13, color: Color(0xFF1A1A2E))),
                  Text(
                      'Casillero: ${widget.clienteFijo!['casillero'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF3949AB))),
                ])),
            const Tooltip(
              message: 'Sucursal tomada de tu perfil',
              child: Icon(Icons.storefront_outlined,
                  color: Color(0xFF1A237E), size: 18),
            ),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      // Tipo
      _FLabel('Tipo de envío'),
      const SizedBox(height: 8),
      Row(children: ['IMPORTACION', 'EXPORTACION'].map((t) {
        final sel = _tipo == t;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: t == 'IMPORTACION' ? 8 : 0),
          child: GestureDetector(
            onTap: () => setState(() => _tipo = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: sel ? const Color(0xFFE8EAF6) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel ? const Color(0xFF1A237E)
                          : const Color(0xFFE5E7EB),
                      width: sel ? 2 : 1)),
              child: Column(children: [
                Icon(t == 'IMPORTACION'
                    ? Icons.flight_land_rounded
                    : Icons.flight_takeoff_rounded,
                    color: sel ? const Color(0xFF1A237E)
                        : const Color(0xFF9CA3AF), size: 20),
                const SizedBox(height: 4),
                Text(t == 'IMPORTACION' ? 'Importación' : 'Exportación',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? const Color(0xFF1A237E)
                            : const Color(0xFF9CA3AF))),
              ]),
            ),
          ),
        ));
      }).toList()),
      const SizedBox(height: 16),

      // Descripción
      _FLabel('Descripción general *'),
      const SizedBox(height: 8),
      TextFormField(
          controller: _descCtrl, maxLines: 2,
          decoration: _fDeco('Ej: Compras Amazon Marzo 2026'),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Campo requerido' : null),
      const SizedBox(height: 16),

      // Categoría
      _FLabel('Categoría del paquete *'),
      const SizedBox(height: 8),
      ...CategoriaPedidoForm.values.map((cat) {
        final sel = _categoria == cat;
        return GestureDetector(
          onTap: () => setState(() => _categoria = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: sel ? const Color(0xFFE8EAF6) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: sel ? const Color(0xFF1A237E)
                        : const Color(0xFFE5E7EB),
                    width: sel ? 2 : 1)),
            child: Row(children: [
              Container(width: 20, height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: sel ? const Color(0xFF1A237E) : Colors.white,
                      border: Border.all(
                          color: sel ? const Color(0xFF1A237E)
                              : const Color(0xFFD1D5DB), width: 2)),
                  child: sel ? const Icon(Icons.check,
                      size: 12, color: Colors.white) : null),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.label, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: sel ? const Color(0xFF1A237E)
                            : const Color(0xFF374151))),
                    Text(cat.description, style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
                  ])),
            ]),
          ),
        );
      }),
      const SizedBox(height: 14),

      // Toggle cotización
      GestureDetector(
        onTap: () => setState(() => _cotizar = !_cotizar),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _cotizar
                  ? const Color(0xFFE8EAF6) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _cotizar
                      ? const Color(0xFF1A237E)
                      : const Color(0xFFE5E7EB))),
          child: Row(children: [
            Icon(_cotizar
                ? Icons.calculate_outlined : Icons.send_outlined,
                color: _cotizar
                    ? const Color(0xFF1A237E)
                    : const Color(0xFF6B7280), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_cotizar
                      ? 'Quiero cotización primero'
                      : 'Enviar directamente sin cotizar',
                      style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 13, color: Color(0xFF374151))),
                  Text(_cotizar
                      ? 'Verás el precio antes de pagar'
                      : 'El admin gestionará tu pedido',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280))),
                ])),
            Switch(value: _cotizar,
                onChanged: (v) => setState(() => _cotizar = v),
                activeColor: const Color(0xFF1A237E)),
          ]),
        ),
      ),
      const SizedBox(height: 16),

      // Sucursales
      _FLabel('Sucursal origen *'),
      const SizedBox(height: 8),
      _loadingSuc
          ? const Center(child: CircularProgressIndicator(
          color: Color(0xFF1A237E)))
          : FormSucDropdown(
          hint: 'Sede exterior donde llega',
          value: _origenId,
          sucursales: _sucursales,
          excluir: _destinoId,
          onChanged: (v) => setState(() => _origenId = v)),
      const SizedBox(height: 14),
      _FLabel('Sucursal destino *'),
      const SizedBox(height: 8),
      FormSucDropdown(
          hint: 'Sucursal en Ecuador',
          value: _destinoId,
          sucursales: _sucursales,
          excluir: _origenId,
          onChanged: (v) => setState(() => _destinoId = v)),
      const SizedBox(height: 20),

      // Productos
      Row(children: [
        const Expanded(child: Text('Mis productos',
            style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)))),
        if (_pesoTotal > 0)
          Text('Total: ${_pesoTotal.toStringAsFixed(2)} lb',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280))),
      ]),
      const SizedBox(height: 12),

      ..._items.asMap().entries.map((e) => FormItemCard(
        index:     e.key,
        item:      _items[e.key],
        onChanged: () => setState(() {}),
        onRemove:  _items.length > 1
            ? () => setState(() => _items.removeAt(e.key))
            : null,
      )),

      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => setState(() => _items.add(ItemFormData())),
        style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A237E),
            side: const BorderSide(color: Color(0xFF1A237E)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12)),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Agregar producto',
            style: TextStyle(fontSize: 13)),
      ),
      const SizedBox(height: 24),

      SizedBox(height: 50, child: ElevatedButton.icon(
        onPressed: _loadingCot ? null : _irPaso2,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        icon: _loadingCot
            ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.arrow_forward_rounded, size: 18),
        label: Text(
            _loadingCot ? 'Generando cotización...'
                : _cotizar
                ? 'Siguiente → Ver cotización'
                : 'Siguiente → Confirmar pago',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      )),
    ]),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 2
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPaso2() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [

    PasoIndicador(pasoActual: 2, total: 3),
    const SizedBox(height: 20),

    if (_cotizar && _cotizacion != null) ...[
      _FLabel('Resumen de cotización'),
      const SizedBox(height: 12),
      CotizacionDesglose(cotizacion: _cotizacion!),
      const SizedBox(height: 20),
    ] else if (!_cotizar) ...[
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF90CAF9))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded,
              color: Color(0xFF1565C0), size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Tu pedido será registrado sin cotización previa. '
                'El equipo lo procesará y te contactará.',
            style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
          )),
        ]),
      ),
      const SizedBox(height: 20),
    ],

    // Forma de pago
    _FLabel('Forma de pago'),
    const SizedBox(height: 10),
    Row(children: ['EFECTIVO', 'TRANSFERENCIA'].map((f) {
      final sel = _formaPago == f;
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: f == 'EFECTIVO' ? 8 : 0),
        child: GestureDetector(
          onTap: () => setState(() => _formaPago = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: sel ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: sel ? const Color(0xFF2E7D32)
                        : const Color(0xFFE5E7EB),
                    width: sel ? 2 : 1)),
            child: Column(children: [
              Icon(f == 'EFECTIVO'
                  ? Icons.payments_outlined
                  : Icons.account_balance_outlined,
                  color: sel ? const Color(0xFF2E7D32)
                      : const Color(0xFF9CA3AF), size: 22),
              const SizedBox(height: 6),
              Text(f == 'EFECTIVO' ? 'Efectivo' : 'Transferencia',
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? const Color(0xFF2E7D32)
                          : const Color(0xFF9CA3AF))),
            ]),
          ),
        ),
      ));
    }).toList()),
    const SizedBox(height: 12),

    if (_formaPago == 'TRANSFERENCIA') ...[
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Expanded(child: Text(
            'En el siguiente paso subirás el comprobante '
                'de la transferencia.',
            style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
          )),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextFormField(
            controller: _bancoCtrl,
            decoration: _fDeco('Banco origen *'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(
            controller: _referenciaCtrl,
            decoration: _fDeco('Referencia (opcional)'))),
      ]),
      const SizedBox(height: 16),
    ],

    if (_formaPago == 'EFECTIVO') ...[
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Expanded(child: Text(
            'En el siguiente paso subirás la foto del recibo '
                'del pago en efectivo.',
            style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
          )),
        ]),
      ),
      const SizedBox(height: 16),
    ],

    // Facturación
    _FLabel('Datos de facturación'),
    const SizedBox(height: 10),
    GestureDetector(
      onTap: () =>
          setState(() => _usarDatosCliente = !_usarDatosCliente),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: _usarDatosCliente
                ? const Color(0xFFE8EAF6) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _usarDatosCliente
                    ? const Color(0xFF1A237E)
                    : const Color(0xFFE5E7EB),
                width: _usarDatosCliente ? 2 : 1)),
        child: Row(children: [
          Icon(_usarDatosCliente
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
              color: _usarDatosCliente
                  ? const Color(0xFF1A237E)
                  : const Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_esPresencial
                    ? 'Usar datos del cliente'
                    : 'Usar mis datos personales',
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 13, color: Color(0xFF374151))),
                const Text('Nombre, cédula y correo registrados',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ])),
        ]),
      ),
    ),
    const SizedBox(height: 10),

    if (!_usarDatosCliente) ...[
      TextFormField(controller: _factRazonCtrl,
          decoration: _fDeco('Razón social o nombre completo')),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(
            controller: _factRucCtrl,
            decoration: _fDeco('RUC / Cédula'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(
            controller: _factTelefonoCtrl,
            decoration: _fDeco('Teléfono'))),
      ]),
      const SizedBox(height: 8),
      TextFormField(controller: _factEmailCtrl,
          decoration: _fDeco('Correo electrónico')),
      const SizedBox(height: 8),
      TextFormField(controller: _factDireccionCtrl,
          decoration: _fDeco('Dirección')),
      const SizedBox(height: 16),
    ],

    const SizedBox(height: 8),

    Row(children: [
      Expanded(child: _cotizar && _cotizacionId != null
          ? OutlinedButton(
          onPressed: _cancelarCotizacion,
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(color: Color(0xFFC62828)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Cancelar',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)))
          : OutlinedButton(
          onPressed: () => setState(() => _paso = 1),
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('← Atrás',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)))),
      const SizedBox(width: 12),
      Expanded(child: SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _submitting ? null : _confirmarPago,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: _submitting
              ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(
              _cotizar ? 'Aprobar y pagar' : 'Confirmar pedido',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      )),
    ]),
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 3
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPaso3() {
    final esTransferencia = _formaPago == 'TRANSFERENCIA';
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      PasoIndicador(pasoActual: 3, total: 3),
      const SizedBox(height: 20),

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0))),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido $_numeroPedido creado',
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 13, color: Color(0xFF2E7D32))),
                const Text('Ahora sube el comprobante de pago',
                    style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
              ])),
        ]),
      ),
      const SizedBox(height: 20),

      _FLabel(esTransferencia
          ? 'Comprobante de transferencia'
          : 'Foto del recibo de efectivo'),
      const SizedBox(height: 12),

      GestureDetector(
        onTap: _loadingImg ? null : _seleccionarImagen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _imagenBase64 != null ? null : 160,
          decoration: BoxDecoration(
              color: _imagenBase64 != null
                  ? Colors.transparent : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _imagenBase64 != null
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE5E7EB),
                  width: _imagenBase64 != null ? 2 : 1)),
          child: _loadingImg
              ? const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(
                  color: Color(0xFF1A237E))))
              : _imagenBase64 != null
              ? Column(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10)),
              child: Image.memory(
                  base64Decode(_imagenBase64!),
                  width: double.infinity,
                  height: 200, fit: BoxFit.cover),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(10))),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(
                    _nombreArchivo ?? 'comprobante',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600))),
                TextButton(
                  onPressed: _seleccionarImagen,
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero),
                  child: const Text('Cambiar',
                      style: TextStyle(fontSize: 11,
                          color: Color(0xFF1A237E))),
                ),
              ]),
            ),
          ])
              : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                      color: Color(0xFFE8EAF6),
                      shape: BoxShape.circle),
                  child: Icon(
                      esTransferencia
                          ? Icons.receipt_long_outlined
                          : Icons.camera_alt_outlined,
                      size: 28, color: const Color(0xFF1A237E)),
                ),
                const SizedBox(height: 10),
                const Text('Toca para seleccionar',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 13, color: Color(0xFF374151))),
                const SizedBox(height: 4),
                const Text('JPG o PNG desde tu galería',
                    style: TextStyle(fontSize: 11,
                        color: Color(0xFF9CA3AF))),
              ]),
        ),
      ),
      const SizedBox(height: 24),

      SizedBox(height: 50, child: ElevatedButton.icon(
        onPressed: _submitting ? null : _subirComprobante,
        style: ElevatedButton.styleFrom(
            backgroundColor: _imagenBase64 != null
                ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        icon: _submitting
            ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.upload_rounded, size: 18),
        label: Text(
            _submitting ? 'Enviando...'
                : _imagenBase64 != null
                ? 'Enviar comprobante'
                : 'Selecciona una imagen primero',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      )),
    ]);
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

class PasoIndicador extends StatelessWidget {
  final int pasoActual, total;
  const PasoIndicador({super.key, required this.pasoActual, required this.total});

  @override
  Widget build(BuildContext context) {
    const labels = ['Datos', 'Pago', 'Comprobante'];
    return Row(children: List.generate(total, (i) {
      final activo   = i + 1 == pasoActual;
      final completo = i + 1 < pasoActual;
      return Expanded(child: Row(children: [
        Expanded(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completo
                      ? const Color(0xFF2E7D32)
                      : activo
                      ? const Color(0xFF1A237E)
                      : const Color(0xFFE5E7EB)),
              child: Center(child: completo
                  ? const Icon(Icons.check_rounded,
                  size: 14, color: Colors.white)
                  : Text('${i + 1}', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  color: activo ? Colors.white
                      : const Color(0xFF9CA3AF)))),
            ),
          ]),
          const SizedBox(height: 4),
          Text(labels[i], style: TextStyle(fontSize: 10,
              fontWeight: FontWeight.w600,
              color: activo
                  ? const Color(0xFF1A237E)
                  : completo
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF9CA3AF))),
        ])),
        if (i < total - 1)
          Container(height: 2, width: 20,
              color: completo
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE5E7EB)),
      ]));
    }));
  }
}

class CotizacionDesglose extends StatelessWidget {
  final Map<String, dynamic> cotizacion;
  const CotizacionDesglose({super.key, required this.cotizacion});

  @override
  Widget build(BuildContext context) {
    final subtotal = (cotizacion['subtotal'] as num?)?.toDouble() ?? 0;
    final iva      = (cotizacion['montoIva'] as num?)?.toDouble() ?? 0;
    final total    = (cotizacion['total'] as num?)?.toDouble() ?? 0;
    final pReal    = (cotizacion['pesoReal'] as num?)?.toDouble();
    final pFact    = (cotizacion['pesoFacturable'] as num?)?.toDouble();
    final detalle  = cotizacion['detalleCalculo']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (pReal != null)
          _Fila('Peso real', '${pReal.toStringAsFixed(2)} lb'),
        if (pFact != null)
          _Fila('Peso facturable', '${pFact.toStringAsFixed(2)} lb'),
        if (detalle.isNotEmpty) ...[
          const Divider(height: 16),
          Text(detalle, style: const TextStyle(
              fontSize: 11, color: Color(0xFF6B7280))),
        ],
        const Divider(height: 16),
        _Fila('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
        _Fila('IVA', '\$${iva.toStringAsFixed(2)}'),
        const Divider(height: 16),
        Row(children: [
          const Text('TOTAL A PAGAR', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15,
              color: Color(0xFF1A1A2E))),
          const Spacer(),
          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18,
              color: Color(0xFF1A237E))),
        ]),
      ]),
    );
  }
}

class _Fila extends StatelessWidget {
  final String label, value;
  const _Fila(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: const TextStyle(
          fontSize: 12, color: Color(0xFF6B7280))),
      const Spacer(),
      Text(value, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: Color(0xFF374151))),
    ]),
  );
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
    final cur   = (value != null && items.any((s) => s['id'] == value))
        ? value : null;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: cur,
            hint: Text(hint, style: const TextStyle(
                color: Color(0xFF9CA3AF), fontSize: 14)),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: items.map((s) => DropdownMenuItem(
                value: s['id'],
                child: Text('${s['nombre']} (${s['pais']})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)))).toList(),
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
    for (final c in [_descCtrl, _trackCtrl, _provCtrl,
      _pesoCtrl, _valorCtrl]) c.dispose();
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
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<TipoProductoForm>(
                      value: widget.item.tipo, isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18),
                      items: TipoProductoForm.values.map((t) =>
                          DropdownMenuItem(value: t,
                              child: Row(children: [
                                Icon(t.icon, size: 16,
                                    color: const Color(0xFF6B7280)),
                                const SizedBox(width: 8),
                                Text(t.label,
                                    style: const TextStyle(fontSize: 13)),
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
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.item.subcategoria.isNotEmpty
                          ? widget.item.subcategoria : null,
                      hint: const Text('Subcategoría (opcional)',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 13)),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18),
                      items: widget.item.tipo.subcategorias.map((s) =>
                          DropdownMenuItem(value: s,
                              child: Text(
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
              // Descripción
              TextFormField(controller: _descCtrl,
                  decoration: _fDeco('Descripción del producto *'),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    widget.item.descripcion = v;
                    widget.onChanged();
                  }),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _trackCtrl,
                    decoration: _fDeco('Tracking (opcional)'),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) {
                      widget.item.tracking = v;
                      widget.onChanged();
                    })),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _provCtrl,
                    decoration: _fDeco('Proveedor'),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) {
                      widget.item.proveedor = v;
                      widget.onChanged();
                    })),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _pesoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _fDeco('Peso (lb)'),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) {
                      widget.item.peso = v;
                      widget.onChanged();
                    })),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _valorCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _fDeco('Valor USD'),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) {
                      widget.item.valorDeclarado = v;
                      widget.onChanged();
                    })),
              ]),
            ]),
      ),
    ]),
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _FLabel extends StatelessWidget {
  final String text;
  const _FLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Color(0xFF374151)));
}

InputDecoration _fDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(
      vertical: 12, horizontal: 14),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
          color: Color(0xFF1A237E), width: 2)),
  errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFC62828))),
  focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
          color: Color(0xFFC62828), width: 2)),
);