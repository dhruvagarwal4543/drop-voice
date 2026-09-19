class AppStrings {
  AppStrings._();

  // App
  static const appName = 'DROPVOICE';
  static const tagline = 'YOUR SQUAD. YOUR COMMS.';

  // Startup
  static const starting = 'Starting DROPVOICE…';
  static const startupFailed = 'Couldn\'t start DROPVOICE';
  static const sessionFailed = 'Couldn\'t start your session';
  static const retry = 'Retry';

  // Home
  static const createRoom = 'CREATE ROOM';
  static const joinRoom = 'JOIN ROOM';

  // Create room
  static const creatingRoom = 'Creating room…';
  static const connectingVoice = 'Connecting voice…';
  static const roomCreateFailed = 'Couldn\'t create room.';
  static const voiceServerUnavailable = 'Voice server unavailable.';

  // Join room
  static const enterRoomCode = 'Enter room code';
  static const join = 'JOIN';
  static const roomNotFound = 'Room not found.';
  static const roomClosed = 'Room is no longer active.';
  static const invalidCode = 'Invalid room code format.';
  static const connectFailed = 'Couldn\'t connect to voice.';

  // Room
  static const connected = 'CONNECTED';
  static const connecting = 'CONNECTING';
  static const reconnecting = 'RECONNECTING';
  static const disconnected = 'DISCONNECTED';
  static const leaveRoom = 'LEAVE';
  static const mute = 'MUTE';
  static const unmute = 'UNMUTE';
  static const participants = 'PARTICIPANTS';
  static const you = 'You';
  static const speaking = 'Speaking';

  // Permissions
  static const micRequired =
      'Microphone access is required for voice chat.';
  static const openSettings = 'Open Settings';

  // Generic
  static const unknownError = 'Something went wrong.';
  static const noConnection = 'No internet connection.';
}
