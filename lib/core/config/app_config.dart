import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get tokenServerUrl {
    final url = dotenv.env['TOKEN_SERVER_URL'];
    if (url == null || url.isEmpty) {
      throw StateError(
        'TOKEN_SERVER_URL is not set in .env. '
        'Please configure the token server URL.',
      );
    }
    return url;
  }

  // LiveKit URL is returned by the token server — not stored here.
  // The Flutter app NEVER holds LIVEKIT_API_KEY or LIVEKIT_API_SECRET.
}
