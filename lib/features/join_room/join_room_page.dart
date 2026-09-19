import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/token_service.dart';
import '../../widgets/dv_logo.dart';
import '../../widgets/dv_text_field.dart';
import '../../widgets/gaming_buttons.dart';
import '../../widgets/state_widgets.dart';

enum _JoinState { input, requestingMic, connecting, error }

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({super.key});

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  _JoinState _state = _JoinState.input;
  String _error = '';
  
  final _codeCtrl = TextEditingController();
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _tokenService = TokenService();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  bool get _isValidCode => _codeCtrl.text.trim().length == 6;

  Future<void> _joinRoom() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) return;

    setState(() => _state = _JoinState.requestingMic);

    // 1. Request Mic Permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required!')),
      );
      return;
    }

    // 2. Request Battery Optimization exemption so BGMI doesn't kill it
    await Permission.ignoreBatteryOptimizations.request();

    setState(() => _state = _JoinState.connecting);

    try {
      // 2. Validate Room in Firestore
      final room = await _firestore.getRoom(code);
      if (room == null) {
        throw Exception('Room $code not found.');
      }
      if (!room.isActive) {
        throw Exception('Room $code is closed.');
      }

      // 3. Get UID
      final uid = _auth.uid;

      // 4. Fetch token from server
      final tokenResponse = await _tokenService.fetchToken(
        roomCode: room.code,
        identity: uid,
        name: 'JOINER_$uid', // Simplified for MVP
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
        _state = _JoinState.error;
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
              if (_state == _JoinState.input || _state == _JoinState.requestingMic) ...[
                const Spacer(),
                const Icon(Icons.radar_rounded, color: Dv.green, size: 64),
                const SizedBox(height: Dv.s32),
                Text(
                  'JOIN SQUAD LINK',
                  style: Dv.headline(size: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dv.s32),
                DvTextField(
                  controller: _codeCtrl,
                  labelText: 'ROOM CODE',
                  hintText: 'e.g. AB3K72',
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (v) => setState(() {}),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'CONNECT',
                  icon: Icons.login_rounded,
                  onPressed: (_isValidCode && _state != _JoinState.requestingMic) ? _joinRoom : null,
                  isLoading: _state == _JoinState.requestingMic,
                ),
              ] else if (_state == _JoinState.connecting) ...[
                const DvLoadingState(message: 'AUTHENTICATING LINK...'),
              ] else if (_state == _JoinState.error) ...[
                DvErrorState(
                  message: _error,
                  onRetry: _joinRoom,
                  onBack: () => setState(() => _state = _JoinState.input),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
