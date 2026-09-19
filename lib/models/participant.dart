/// Participant is derived ENTIRELY from LiveKit events — never from Firestore.
/// This model is a local representation of what LiveKit tells us.
class Participant {
  const Participant({
    required this.identity,
    required this.name,
    required this.isLocal,
    this.isSpeaking = false,
    this.isMuted = false,
  });

  /// LiveKit participant identity (Firebase UID).
  final String identity;

  /// Display name (or identity if name not set).
  final String name;

  /// Is this the local device's participant?
  final bool isLocal;

  /// LiveKit speaking state (driven by audio level events).
  final bool isSpeaking;

  /// Microphone muted state.
  final bool isMuted;

  Participant copyWith({
    bool? isSpeaking,
    bool? isMuted,
  }) {
    return Participant(
      identity: identity,
      name: name,
      isLocal: isLocal,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
