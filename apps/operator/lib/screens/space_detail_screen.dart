import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import '../widgets/status_chip.dart';

class SpaceDetailScreen extends StatefulWidget {
  const SpaceDetailScreen({
    super.key,
    required this.api,
    required this.spaceId,
  });

  final ParkimetroApi api;
  final String spaceId;

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  late Future<ParkingSpace> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getSpace(widget.spaceId);
  }

  void _reload() {
    setState(() {
      _future = widget.api.getSpace(widget.spaceId);
    });
  }

  Future<void> _setStatus(SpaceStatus status) async {
    try {
      await widget.api.changeStatus(widget.spaceId, status);
      _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _reserve() async {
    final result = await showDialog<_ClientActionResult>(
      context: context,
      builder: (context) => _ClientActionDialog(
        api: widget.api,
        title: 'Reservar espacio',
        confirmLabel: 'Reservar',
        askStartTime: true,
      ),
    );
    if (result == null) {
      return;
    }
    try {
      await widget.api.reserveSpace(
        widget.spaceId,
        dni: result.dni,
        clientName: result.clientName,
        startsAt: result.startsAt!,
        limitUntil: result.limitUntil,
      );
      _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _occupy(ParkingSpace space) async {
    final result = await showDialog<_ClientActionResult>(
      context: context,
      builder: (context) => _ClientActionDialog(
        api: widget.api,
        title: 'Iniciar ocupación',
        confirmLabel: 'Ocupar',
        showPlate: true,
        initialDni: space.clientDni,
        initialName: space.clientName,
        initialLimitUntil: space.limitUntil,
      ),
    );
    if (result == null) {
      return;
    }
    try {
      await widget.api.startSession(
        widget.spaceId,
        dni: result.dni,
        clientName: result.clientName,
        licensePlate: result.plate,
        limitUntil: result.limitUntil,
      );
      _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _release(ParkingSpace space) async {
    try {
      if (space.activeSessionId != null) {
        final ended = await widget.api.endSession(space.activeSessionId!);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cobrado ${formatSoles(ended.amount)} (${ended.billedHours} h o fracción)',
            ),
          ),
        );
      } else {
        await widget.api.changeStatus(space.id, SpaceStatus.free);
      }
      _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espacio')),
      body: FutureBuilder<ParkingSpace>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final space = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text(
                    space.code,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 12),
                  StatusChip(status: space.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(space.zoneName),
              Text(rateLabel(space.hourlyRate)),
              Text('Lat ${space.latitude}, Lng ${space.longitude}'),
              if (space.notes != null) Text(space.notes!),
              if (space.clientName != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Cliente: ${space.clientName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('DNI ${space.clientDni}'),
                if (space.reservedFrom != null)
                  Text('Inicio: ${_formatStayTime(space.reservedFrom!)}'),
                if (space.limitUntil != null)
                  Text('Fin estimado: ${_formatStayTime(space.limitUntil!)}'),
              ],
              if (space.occupiedSince != null) ...[
                const SizedBox(height: 16),
                OccupancyClock(
                  startedAt: space.occupiedSince!,
                  hourlyRate: space.hourlyRate,
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: space.status == SpaceStatus.occupied
                        ? null
                        : () => _occupy(space),
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Ocupar'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: space.status == SpaceStatus.free
                        ? null
                        : () => _release(space),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Liberar'),
                  ),
                  OutlinedButton(
                    onPressed: _reserve,
                    child: const Text('Reservar'),
                  ),
                  OutlinedButton(
                    onPressed: () => _setStatus(SpaceStatus.outOfService),
                    child: const Text('Fuera de servicio'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientActionResult {
  const _ClientActionResult({
    required this.dni,
    required this.limitUntil,
    this.clientName,
    this.plate,
    this.startsAt,
  });

  final String dni;
  final String? clientName;
  final String? plate;
  final DateTime? startsAt;
  final DateTime limitUntil;
}

class _ClientActionDialog extends StatefulWidget {
  const _ClientActionDialog({
    required this.api,
    required this.title,
    required this.confirmLabel,
    this.showPlate = false,
    this.askStartTime = false,
    this.initialDni,
    this.initialName,
    this.initialLimitUntil,
  });

  final ParkimetroApi api;
  final String title;
  final String confirmLabel;
  final bool showPlate;
  final bool askStartTime;
  final String? initialDni;
  final String? initialName;
  final DateTime? initialLimitUntil;

  @override
  State<_ClientActionDialog> createState() => _ClientActionDialogState();
}

class _ClientActionDialogState extends State<_ClientActionDialog> {
  late final TextEditingController _dni;
  late final TextEditingController _name;
  final _plate = TextEditingController();
  late String _lookupHint;
  late DateTime _startsAt;
  late DateTime _limitUntil;

  @override
  void initState() {
    super.initState();
    _dni = TextEditingController(text: widget.initialDni ?? '');
    _name = TextEditingController(text: widget.initialName ?? '');
    _lookupHint = widget.initialName == null
        ? 'Si el padrón no lo trae, escríbelo aquí.'
        : 'Datos de la reserva.';
    final now = DateTime.now();
    _startsAt = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final suggestedEnd = widget.initialLimitUntil?.toLocal();
    _limitUntil = suggestedEnd != null && suggestedEnd.isAfter(_startsAt)
        ? suggestedEnd
        : _startsAt.add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _dni.dispose();
    _name.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    try {
      final found = await widget.api.lookupClient(_dni.text.trim());
      setState(() {
        _name.text = found.name;
        _lookupHint = 'Nombre encontrado en el padrón.';
      });
    } on ApiException catch (error) {
      setState(() {
        _lookupHint = error.statusCode == 404
            ? 'No se encontró. Ingresa el nombre completo.'
            : error.message;
      });
      if (error.statusCode != 404 && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _startsAt : _limitUntil;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null || !mounted) {
      return;
    }
    var next = DateTime(
      current.year,
      current.month,
      current.day,
      picked.hour,
      picked.minute,
    );
    setState(() {
      if (start) {
        _startsAt = next;
        if (!_limitUntil.isAfter(_startsAt)) {
          _limitUntil = _startsAt.add(const Duration(hours: 2));
        }
      } else {
        final floor = widget.askStartTime ? _startsAt : DateTime.now();
        if (!next.isAfter(floor)) {
          next = next.add(const Duration(days: 1));
        }
        _limitUntil = next;
      }
    });
  }

  void _confirm() {
    final start = widget.askStartTime ? _startsAt : DateTime.now();
    if (!_limitUntil.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La hora de fin estimada debe ser posterior al inicio.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _ClientActionResult(
        dni: _dni.text.trim(),
        clientName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        plate: _plate.text.trim().isEmpty ? null : _plate.text.trim(),
        startsAt: widget.askStartTime ? _startsAt : null,
        limitUntil: _limitUntil,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _dni,
              decoration: const InputDecoration(labelText: 'DNI del cliente'),
              keyboardType: TextInputType.number,
              maxLength: 8,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _lookup,
                child: const Text('Buscar'),
              ),
            ),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                helperText: _lookupHint,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            if (widget.showPlate) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _plate,
                decoration: const InputDecoration(
                  labelText: 'Placa (opcional)',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
            const SizedBox(height: 8),
            if (widget.askStartTime)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hora de inicio'),
                subtitle: Text(_formatStayTime(_startsAt)),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickTime(start: true),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hora de fin estimada'),
              subtitle: Text(
                widget.askStartTime
                    ? _formatStayTime(_limitUntil)
                    : '${_formatStayTime(_limitUntil)}\nEl inicio lo registra el servidor al ocupar.',
              ),
              trailing: const Icon(Icons.event),
              onTap: () => _pickTime(start: false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

String _formatStayTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}
