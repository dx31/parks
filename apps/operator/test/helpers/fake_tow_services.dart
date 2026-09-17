import 'package:flutter/material.dart';
import 'package:operator_app/tow/tow_services.dart';

class FakeTowServices implements TowServices {
  FakeTowServices({
    this.photoPath = 'tow-photo.jpg',
    this.location = const TowCoordinate(
      latitude: -12.046374,
      longitude: -77.042793,
    ),
    this.locationError,
    this.photoError,
  });

  String? photoPath;
  TowCoordinate location;
  String? locationError;
  String? photoError;
  String? lastSharedText;
  String? lastSharedImage;
  int captureCount = 0;
  bool lastFromCamera = false;

  @override
  Future<String?> capturePhoto({required bool fromCamera}) async {
    lastFromCamera = fromCamera;
    captureCount += 1;
    if (photoError != null) {
      throw TowException(photoError!);
    }
    return photoPath;
  }

  @override
  Future<TowCoordinate> currentLocation() async {
    if (locationError != null) {
      throw TowException(locationError!);
    }
    return location;
  }

  @override
  Future<void> share({
    required String text,
    required String imagePath,
    Rect? shareOrigin,
  }) async {
    lastSharedText = text;
    lastSharedImage = imagePath;
  }
}
