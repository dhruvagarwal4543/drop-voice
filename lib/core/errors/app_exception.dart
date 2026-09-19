/// Typed exception hierarchy for DROPVOICE.
/// Use these instead of bare Exception/Error so we can show
/// specific user-facing messages and handle each case distinctly.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Firebase or anonymous auth failed.
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Firestore read/write failed.
class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

/// Room code not found, already closed, or bad format.
class RoomException extends AppException {
  const RoomException(super.message);
}

/// Token server returned an error or is unreachable.
class TokenException extends AppException {
  const TokenException(super.message);
}

/// LiveKit connection failed.
/// Named VoiceException to avoid clash with livekit_client's LiveKitException.
class VoiceException extends AppException {
  const VoiceException(super.message);
}

/// Microphone permission denied or unavailable.
class MicrophoneException extends AppException {
  const MicrophoneException(super.message);
}

/// Network request timed out.
class TimeoutException extends AppException {
  const TimeoutException(super.message);
}
