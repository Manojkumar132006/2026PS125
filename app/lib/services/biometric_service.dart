import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Checks whether the hardware supports biometric authentication
  static Future<bool> canAuthenticate() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Retrieves list of available biometric hardware sensors (fingerprint, face, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Triggers the native Android BiometricPrompt (or iOS TouchID/FaceID)
  static Future<bool> authenticate({required String reason}) async {
    try {
      final canAuth = await canAuthenticate();
      if (!canAuth) {
        throw PlatformException(
          code: 'NotAvailable',
          message: 'Biometric hardware not available or no fingerprint enrolled.',
        );
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Supports Fingerprint, with PIN/pattern fallback
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService PlatformException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('BiometricService error: $e');
      return false;
    }
  }
}
