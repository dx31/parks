import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final SpaceStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      SpaceStatus.free => (Colors.green, spaceStatusLabel(status)),
      SpaceStatus.occupied => (Colors.red, spaceStatusLabel(status)),
      SpaceStatus.reserved => (Colors.orange, spaceStatusLabel(status)),
      SpaceStatus.outOfService => (Colors.grey, spaceStatusLabel(status)),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color.shade800, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    );
  }
}
