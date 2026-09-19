import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/token_service.dart';
import '../../widgets/dv_logo.dart';
import '../../widgets/gaming_buttons.dart';
import '../../widgets/state_widgets.dart';

enum _CreateState { initial, requestingMic, creating, error }

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  _CreateState _state = _CreateState.initial;
  String _error = '';

  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _tokenService = TokenService();

  Future<void> _createRoom() async {
    setState(() => _state = _CreateState.requestingMic);

    // 1. Request Mic Permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      setState(() {
        _state = _CreateState.error;
        _error = 'Microphone permission denied.\nVoice comms require mic access.';
      });
      return;
    }

    // 2. Request Battery Optimization exemption so BGMI doesn't kill it
    await Permission.ignoreBatteryOptimizations.request();

    setState(() => _state = _CreateState.creating);

    try {
      // 2. Get UID
      final uid = _auth.uid;

      // 3. Create room in Firestore
      final room = await _firestore.createRoom(hostId: uid);

      // 4. Fetch token from server
      final tokenResponse = await _tokenService.fetchToken(
        roomCode: room.code,
        identity: uid,
        name: 'HOST_$uid', // Simplified for MVP
      );

      if (!mounted) return;

      // 5. Navigate to Room
      context.pushReplacement(
        '/room/${room.code}',
        extra: {
          'token': tokenResponse.token,
          'livekitUrl': tokenResponse.livekitUrl,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CreateState.error;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dv.obsidian,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const DvLogo(size: 20),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dv.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_state == _CreateState.initial || _state == _CreateState.requestingMic) ...[
                const Spacer(),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Dv.graphite,
                    shape: BoxShape.circle,
                    border: Border.all(color: Dv.steel),
                  ),
                  child: const Icon(Icons.mic_none_rounded, color: Dv.green, size: 36),
                ),
                const SizedBox(height: Dv.s32),
                Text(
                  'NEW TACTICAL LINK',
                  style: Dv.headline(size: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dv.s12),
                Text(
                  'We need microphone access to establish your voice channel. Tap below to begin.',
                  style: Dv.body(color: Dv.ash),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'AUTHORIZE & CREATE',
                  icon: Icons.shield_rounded,
                  onPressed: _state == _CreateState.requestingMic ? null : _createRoom,
                  isLoading: _state == _CreateState.requestingMic,
                ),
              ] else if (_state == _CreateState.creating) ...[
                const DvLoadingState(message: 'INITIALIZING COMMS...'),
              ] else if (_state == _CreateState.error) ...[
                DvErrorState(
                  message: _error,
                  onRetry: _createRoom,
                  onBack: () => setState(() => _state = _CreateState.initial),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
