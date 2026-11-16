import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const CarmelitasApp());
}

class CarmelitasApp extends StatelessWidget {
  const CarmelitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Contable Carmelitas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D4037),
          surface: const Color(0xFFF5EFE6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5EFE6),
      ),
      home: const HomeContable(),
    );
  }
}

class HomeContable extends StatefulWidget {
  const HomeContable({super.key});

  @override
  State<HomeContable> createState() => _HomeContableState();
}

class _HomeContableState extends State<HomeContable> {
  int _tabIndex = 0;
  List<Map<String, dynamic>> _movs = [];
  String _comunidad = "Comunidad Carmelitas Cumaná";
  String _economa = "Hna. Ecónoma";
  String _cedula = "V-00.000.000";

  String _tipo = "Ingreso";
  String _cuenta = "Caja Efectivo (Bs.)";
  String _categoria = "Ofrendas y Colectas";
  String _filtroCuenta = "Todas";
  final _montoCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final List<String> _catIng = [
    "Ofrendas y Colectas",
    "Diezmos",
    "Donaciones",
    "Subsidios / Ayudas",
    "Otros Ingresos"
  ];
  final List<String> _catEgr = [
    "Alimentación y Víveres",
    "Salud y Medicinas",
    "Servicios Públicos",
    "Mantenimiento y Reparaciones",
    "Liturgia y Sacristía",
    "Ayuda Social / Caridad",
    "Aporte Casa General",
    "Otros Egresos"
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _comunidad = prefs.getString('comunidad') ?? _comunidad;
      _economa = prefs.getString('economa') ?? _economa;
      _cedula = prefs.getString('cedula') ?? _cedula;
      final raw = prefs.getString('movimientos');
      if (raw != null) {
        _movs = List<Map<String, dynamic>>.from(jsonDecode(raw));
      }
    });
  }

  Future<void> _guardarStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comunidad', _comunidad);
    await prefs.setString('economa', _economa);
    await prefs.setString('cedula', _cedula);
    await prefs.setString('movimientos', jsonEncode(_movs));
  }

  String _fmt(double val, String cta) {
    final f = NumberFormat("#,##0.00", "es_VE");
    return cta.contains("\$") ? "\$ ${f.format(val)}" : "Bs. ${f.format(val)}";
  }

  double _saldoCuenta(String cta) {
    double total = 0;
    for (var m in _movs) {
      if (m['cuenta'] == cta) {
        total += m['tipo'] == 'Ingreso' ? m['monto'] : -m['monto'];
      }
    }
    return total;
  }

  void _registrarMovimiento() async {
    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;
    final desc = _descCtrl.text.trim();
    if (monto <= 0 || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese un monto válido y una descripción.")),
      );
      return;
    }

    final numRecibo = _movs.where((m) => m['tipo'] == _tipo).length + 1;
    final ahora = DateTime.now();
    final nuevo = {
      'id': ahora.millisecondsSinceEpoch,
      'num': numRecibo,
      'fecha': DateFormat('dd/MM/yyyy HH:mm').format(ahora),
      'ym': DateFormat('yyyy-MM').format(ahora),
      'tipo': _tipo,
      'cuenta': _cuenta,
      'categoria': _categoria,
      'ref': _refCtrl.text.trim().isEmpty ? 'S/N' : _refCtrl.text.trim(),
      'monto': monto,
      'desc': desc,
    };

    setState(() {
      _movs.insert(0, nuevo);
      _montoCtrl.clear();
      _refCtrl.clear();
      _descCtrl.clear();
      _tabIndex = 0;
    });
    await _guardarStorage();
    if (mounted) _mostrarReciboDialog(nuevo);
  }

  void _mostrarReciboDialog(Map<String, dynamic> m) {
    final esIng = m['tipo'] == 'Ingreso';
    final titulo = esIng
        ? "COMPROBANTE DE INGRESO / DONACIÓN"
        : "COMPROBANTE DE EGRESO / PAGO";
    final numStr = m['num'].toString().padLeft(4, '0');
    final montoStr = _fmt((m['monto'] as num).toDouble(), m['cuenta']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Column(
          children: [
            const Text(
              "HERMANAS CARMELITAS DE MADRE CANDELARIA",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
            ),
            Text(_comunidad, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Divider(),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF5EFE6), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("N° $numStr\n${m['fecha']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    montoStr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: esIng ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text("Cuenta: ${m['cuenta']}", style: const TextStyle(fontSize: 13)),
            Text("Categoría: ${m['categoria']}", style: const TextStyle(fontSize: 13)),
            Text("Referencia: ${m['ref']}", style: const TextStyle(fontSize: 13)),
            Text("Concepto: ${m['desc']}", style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                "Emitido por: $_economa (C.I.: $_cedula)",
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              final texto = "*$titulo N° $numStr*\n"
                  "⛪ *$_comunidad*\n"
                  "📅 Fecha: ${m['fecha']}\n"
                  "💰 Monto: *$montoStr* (${m['cuenta']})\n"
                  "📂 Categoría: ${m['categoria']}\n"
                  "📝 Concepto: ${m['desc']}\n"
                  "✍️ Ecónoma: $_economa";
              Share.share(texto);
            },
            icon: const Icon(Icons.share, color: Colors.green),
            label: const Text("Compartir", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _abrirConfig() {
    final cCom = TextEditingController(text: _comunidad);
    final cEco = TextEditingController(text: _economa);
    final cCed = TextEditingController(text: _cedula);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Datos de la Comunidad"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cCom, decoration: const InputDecoration(labelText: "Nombre de la Comunidad")),
            TextField(controller: cEco, decoration: const InputDecoration(labelText: "Hermana Ecónoma")),
            TextField(controller: cCed, decoration: const InputDecoration(labelText: "Cédula de Identidad")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _comunidad = cCom.text.trim().isEmpty ? _comunidad : cCom.text.trim();
                _economa = cEco.text.trim().isEmpty ? _economa : cEco.text.trim();
                _cedula = cCed.text.trim().isEmpty ? _cedula : cCed.text.trim();
              });
              await _guardarStorage();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movsFiltrados = _filtroCuenta == "Todas"
        ? _movs
        : _movs.where((m) => m['cuenta'] == _filtroCuenta).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_comunidad.toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFFEFEBE9))),
            const Text("Sistema Contable Carmelitas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
