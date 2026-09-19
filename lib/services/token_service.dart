import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/constants/constants.dart';
import '../core/errors/app_exception.dart';
import 'auth_service.dart';

class TokenResponse {
  const TokenResponse({required this.token, required this.livekitUrl});

  final String token;
  final String livekitUrl;
}

class TokenService {
  TokenService({http.Client? client, AuthService? auth})
      : _client = client ?? http.Client(),
        _auth = auth ?? AuthService();

  final http.Client _client;
  final AuthService _auth;

  /// Fetches a short-lived LiveKit token from the token server.
  /// Sends Firebase ID token in the Authorization header.
  /// The LIVEKIT_API_SECRET never exists in this app.
  Future<TokenResponse> fetchToken({
    required String roomCode,
    required String identity,
    required String name,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.tokenServerUrl}${ApiPaths.token}',
    );

    try {
      // Get fresh Firebase ID token for server-side verification
      final idToken = await _auth.getIdToken();

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'room': roomCode,
              'identity': identity,
              'name': name,
            }),
          )
          .timeout(Timeouts.tokenFetch);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final token = body['token'] as String?;
        final livekitUrl = body['livekitUrl'] as String?;

        if (token == null || token.isEmpty) {
          throw const TokenException('Token server returned empty token.');
        }
        if (livekitUrl == null || livekitUrl.isEmpty) {
          throw const TokenException('Token server returned no LiveKit URL.');
        }

        return TokenResponse(token: token, livekitUrl: livekitUrl);
      } else if (response.statusCode == 401) {
        throw const TokenException('Authentication failed. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const TokenException('Unauthorized. Identity mismatch.');
      } else if (response.statusCode == 404) {
        throw const TokenException('Room not found on token server.');
      } else {
        throw TokenException(
          'Token server error: ${response.statusCode}',
        );
      }
    } on TokenException {
      rethrow;
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timeout')) {
        throw const TimeoutException(
          'Token server timed out. Check your connection.',
        );
      }
      throw TokenException('Could not reach token server: $e');
    }
  }
}
