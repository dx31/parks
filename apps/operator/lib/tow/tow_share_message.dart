String buildTowShareMessage({
  required String zoneName,
  required String city,
  required String plate,
  required String notes,
  required double latitude,
  required double longitude,
}) {
  final lat = latitude.toStringAsFixed(6);
  final lng = longitude.toStringAsFixed(6);
  final buffer = StringBuffer()
    ..writeln('Solicitud de grúa')
    ..writeln('Zona: $zoneName')
    ..writeln('Ciudad: $city')
    ..writeln('Placa: $plate');
  final trimmedNotes = notes.trim();
  if (trimmedNotes.isNotEmpty) {
    buffer.writeln('Indicaciones: $trimmedNotes');
  }
  buffer
    ..writeln('Ubicación: $lat, $lng')
    ..write('Mapa: https://maps.google.com/?q=$lat,$lng');
  return buffer.toString();
}
