import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/checkpoint_model.dart';

/// Outcome of a photo verification check.
sealed class PhotoVerificationResult {
  const PhotoVerificationResult();
}

final class PhotoVerificationSuccess extends PhotoVerificationResult {
  const PhotoVerificationSuccess();
}

final class PhotoVerificationFailure extends PhotoVerificationResult {
  const PhotoVerificationFailure(this.message);

  final String message;
}

/// Service for verifying user-captured photos against checkpoint criteria.
class PhotoVerificationService {
  /// Verifies [photoFile] against [checkpoint] requirements:
  /// 1. Real-time GPS Proximity check (if [distanceInMeters] is provided).
  /// 2. On-Device AI OCR Vision check (if [checkpoint.targetText] is present).
  static Future<PhotoVerificationResult> verifyPhoto({
    required File photoFile,
    required CheckpointModel checkpoint,
    required double? distanceInMeters,
  }) async {
    // ── 1. Real-time GPS Proximity Verification ──
    final unlockRadius = checkpoint.unlockRadius.toDouble();
    if (distanceInMeters != null && distanceInMeters > unlockRadius) {
      return PhotoVerificationFailure(
        '📍 Location Verification Failed! You are ${distanceInMeters.toInt()}m away. Walk within ${checkpoint.unlockRadius}m of the stop to take the photo!',
      );
    }

    // ── 2. On-Device AI OCR Vision Verification ──
    final targetText = checkpoint.targetText;
    if (targetText != null && targetText.trim().isNotEmpty) {
      final inputImage = InputImage.fromFilePath(photoFile.path);
      final textRecognizer = TextRecognizer();
      try {
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        final scannedContent = recognizedText.text.toUpperCase();
        final expected = targetText.trim().toUpperCase();

        if (!scannedContent.contains(expected)) {
          return PhotoVerificationFailure(
            '❌ Verification Failed: Could not detect "$targetText" in the photo! Please frame the required text or sign clearly in your picture.',
          );
        }
      } catch (err) {
        debugPrint('OCR Scan error: $err');
        return PhotoVerificationFailure(
          '❌ Verification Failed: Unable to scan text in photo. Please ensure good lighting and try again.',
        );
      }
    }

    return const PhotoVerificationSuccess();
  }
}
