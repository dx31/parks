import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class TowException implements Exception {
  const TowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TowCoordinate {
  const TowCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

abstract class TowServices {
  const TowServices();

  Future<String?> capturePhoto({required bool fromCamera});

  Future<TowCoordinate> currentLocation();

  Future<void> share({
    required String text,
    required String imagePath,
    Rect? shareOrigin,
  });
}

class DeviceTowServices implements TowServices {
  const DeviceTowServices();

  @override
  Future<String?> capturePhoto({required bool fromCamera}) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      return file?.path;
    } catch (_) {
      throw TowException(
        fromCamera
            ? 'No se pudo abrir la cámara. Prueba elegir una foto de la galería.'
            : 'No se pudo elegir la foto del vehículo.',
      );
    }
  }

  @override
  Future<TowCoordinate> currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const TowException(
        'Activa el GPS para incluir la ubicación del vehículo.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const TowException(
        'Necesitamos el permiso de ubicación para compartir el punto del vehículo.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return TowCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      throw const TowException(
        'No se pudo obtener la geolocalización. Inténtalo de nuevo.',
      );
    }
  }

  @override
  Future<void> share({
    required String text,
    required String imagePath,
    Rect? shareOrigin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath, mimeType: 'image/jpeg')],
        text: text,
        subject: 'Solicitud de grúa',
        sharePositionOrigin: shareOrigin,
      ),
    );
  }
}
