import 'dart:async';

import 'package:flutter/material.dart';

import 'billing.dart';
import 'models.dart';

class OccupancyClock extends StatefulWidget {
  const OccupancyClock({
    super.key,
    required this.startedAt,
    required this.hourlyRate,
    this.compact = false,
  });

  @visibleForTesting
  static bool live = true;

  final DateTime startedAt;
  final double hourlyRate;
  final bool compact;

  @override
  State<OccupancyClock> createState() => _OccupancyClockState();
}

class _OccupancyClockState extends State<OccupancyClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (OccupancyClock.live) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final elapsed = formatOccupiedDuration(widget.startedAt, now);
    final hours = hoursOrFraction(widget.startedAt, now);
    final amount = billedAmount(widget.startedAt, now, widget.hourlyRate);
    final charge = '${formatSoles(amount)} ($hours h o fracción)';
    if (widget.compact) {
      return Text('Ocupado $elapsed · $charge');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inicio: ${_formatStart(widget.startedAt)}'),
        Text('Tiempo ocupado: $elapsed'),
        Text('Cargo actual: $charge'),
      ],
    );
  }

  String _formatStart(DateTime startedAt) {
    final local = startedAt.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

class StayLimitIcon extends StatefulWidget {
  const StayLimitIcon({super.key, required this.space});

  final ParkingSpace space;

  @override
  State<StayLimitIcon> createState() => _StayLimitIconState();
}

class _StayLimitIconState extends State<StayLimitIcon> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (OccupancyClock.live && widget.space.limitUntil != null) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.space.exceededStay()) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: 'Se excedió la hora de salida estimada',
      child: Icon(
        Icons.warning_amber_rounded,
        color: Colors.deepOrange.shade700,
      ),
    );
  }
}
