import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

class SpaceFormScreen extends StatefulWidget {
  const SpaceFormScreen({super.key, required this.api, required this.zone});

  final ParkimetroApi api;
  final Zone zone;

  @override
  State<SpaceFormScreen> createState() => _SpaceFormScreenState();
}

class _SpaceFormScreenState extends State<SpaceFormScreen> {
  final _code = TextEditingController();
  final _latitude = TextEditingController(text: '19.4326');
  final _longitude = TextEditingController(text: '-99.1332');
  final _rate = TextEditingController(text: '18');
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.api.createSpace(
        code: _code.text.trim(),
        zoneId: widget.zone.id,
        latitude: double.parse(_latitude.text),
        longitude: double.parse(_longitude.text),
        hourlyRate: double.parse(_rate.text),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on FormatException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa latitud, longitud y tarifa.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar espacio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Zona: ${widget.zone.name}'),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            decoration: const InputDecoration(
              labelText: 'Código',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _latitude,
            decoration: const InputDecoration(
              labelText: 'Latitud',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _longitude,
            decoration: const InputDecoration(
              labelText: 'Longitud',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rate,
            decoration: const InputDecoration(
              labelText: 'Tarifa por hora',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notas',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Guardar espacio'),
          ),
        ],
      ),
    );
  }
}
