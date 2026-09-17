import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import '../tow/tow_services.dart';
import '../tow/tow_share_message.dart';

class TowRequestScreen extends StatefulWidget {
  const TowRequestScreen({super.key, required this.zone, this.services});

  final Zone zone;
  final TowServices? services;

  @override
  State<TowRequestScreen> createState() => _TowRequestScreenState();
}

class _TowRequestScreenState extends State<TowRequestScreen> {
  final _plate = TextEditingController();
  final _notes = TextEditingController();
  late final TowServices _services;
  String? _photoPath;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _services = widget.services ?? const DeviceTowServices();
  }

  @override
  void dispose() {
    _plate.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    try {
      final path = await _services.capturePhoto(fromCamera: fromCamera);
      if (!mounted || path == null) {
        return;
      }
      setState(() => _photoPath = path);
    } on TowException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _share() async {
    final plate = _plate.text.trim().toUpperCase();
    final photoPath = _photoPath;
    if (plate.isEmpty) {
      _showMessage('Indica la placa del vehículo.');
      return;
    }
    if (photoPath == null) {
      _showMessage('Toma una foto del vehículo a incautar.');
      return;
    }

    setState(() => _busy = true);
    try {
      final location = await _services.currentLocation();
      final text = buildTowShareMessage(
        zoneName: widget.zone.name,
        city: widget.zone.city,
        plate: plate,
        notes: _notes.text,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      final origin = _shareOrigin();
      await _services.share(
        text: text,
        imagePath: photoPath,
        shareOrigin: origin,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Solicitud lista para enviar por mensajería.');
    } on TowException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('No se pudo abrir el menú para compartir.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar grúa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.zone.name} · ${widget.zone.city}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Se generará un mensaje con la foto y tu geolocalización para compartirlo por WhatsApp u otra app. No se guarda en el servidor.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Placa del vehículo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Indicaciones adicionales',
              hintText: 'Color, modelo, punto de referencia…',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Foto del vehículo',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _PhotoPreview(
            path: _photoPath,
            onClear: _photoPath == null
                ? null
                : () => setState(() => _photoPath = null),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _pickPhoto(fromCamera: true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickPhoto(fromCamera: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            label: Text(_busy ? 'Preparando…' : 'Compartir solicitud'),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path, this.onClear});

  final String? path;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: path == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 48),
                      SizedBox(height: 8),
                      Text('Sin foto'),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    _photoImage(path!),
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: _PhotoReadyBadge(),
                    ),
                    if (onClear != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton.filledTonal(
                          tooltip: 'Quitar foto',
                          onPressed: onClear,
                          icon: const Icon(Icons.close),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _photoImage(String filePath) {
    if (kIsWeb) {
      return const Center(child: Icon(Icons.photo, size: 64));
    }
    return Image.file(
      File(filePath),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.directions_car, size: 64)),
    );
  }
}

class _PhotoReadyBadge extends StatelessWidget {
  const _PhotoReadyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Foto lista',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
