/// Room code constants.
class RoomConstants {
  RoomConstants._();

  /// Length of generated room codes.
  static const int codeLength = 6;

  /// Valid characters in a room code (uppercase only, no ambiguous chars).
  static const String codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Firestore collection for rooms.
  static const String roomsCollection = 'rooms';

  /// Maximum participants per room (not enforced server-side yet, UI hint only).
  static const int maxParticipants = 10;
}

/// Token server endpoint paths.
class ApiPaths {
  ApiPaths._();
  static const String token = '/token';
  static const String health = '/health';
}

/// Timeout durations.
class Timeouts {
  Timeouts._();
  static const Duration startup = Duration(seconds: 10);
  static const Duration tokenFetch = Duration(seconds: 8);
  static const Duration roomJoin = Duration(seconds: 15);
}
