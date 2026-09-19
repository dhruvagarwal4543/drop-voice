import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../models/participant.dart' as model;
import '../../services/livekit_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../core/errors/app_exception.dart';
import '../../widgets/gaming_buttons.dart';
import '../../widgets/participant_card.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/telemetry_label.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({
    super.key,
    required this.roomCode,
    required this.token,
    required this.livekitUrl,
  });

  final String roomCode;
  final String token;
  final String livekitUrl;

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final _livekitService = LiveKitService();
  final _userService = UserService();
  final _auth = AuthService();

  lk.ConnectionState _connectionState = lk.ConnectionState.disconnected;
  List<model.Participant> _participants = [];
  bool _isConnecting = true;
  String? _errorMessage;
  bool _isMuted = false;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    _connectToRoom();
    // Mark user as inRoom
    try { _userService.updateStatus(_auth.uid, UserStatus.inRoom); } catch (_) {}
  }

  void _subscribeToStreams() {
    _livekitService.participantsStream.listen((participants) {
      if (mounted) {
        setState(() {
          _participants = participants;
          _isMuted = _livekitService.isMicMuted;
        });
      }
    });
    _livekitService.connectionStateStream.listen((state) {
      if (mounted) setState(() => _connectionState = state);
    });
  }

  Future<void> _connectToRoom() async {
    try {
      await _livekitService.connect(url: widget.livekitUrl, token: widget.token);
      if (mounted) setState(() => _isConnecting = false);
    } on VoiceException catch (e) {
      if (mounted) setState(() { _isConnecting = false; _errorMessage = 'CONNECTION REFUSED:\n${e.message}'; });
    } catch (e) {
      if (mounted) setState(() { _isConnecting = false; _errorMessage = 'UNEXPECTED ERROR:\n$e'; });
    }
  }

  Future<void> _toggleMic() async {
    await _livekitService.toggleMicrophone();
    if (mounted) setState(() => _isMuted = _livekitService.isMicMuted);
  }

  Future<void> _leaveRoom() async {
    await _livekitService.disconnect();
    try { _userService.updateStatus(_auth.uid, UserStatus.online); } catch (_) {}
    if (mounted) context.go('/home');
  }

  Future<void> _copyRoomCode() async {
    await Clipboard.setData(ClipboardData(text: widget.roomCode));
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() => _codeCopied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Dv.green, size: 18),
            const SizedBox(width: Dv.s8),
            Text('ROOM CODE COPIED', style: Dv.mono(size: 12, color: Dv.white)),
          ]),
          backgroundColor: Dv.graphite,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dv.r8), side: const BorderSide(color: Dv.green)),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _codeCopied = false);
      });
    }
  }

  Future<void> _shareRoom() async {
    HapticFeedback.lightImpact();
    await Share.share(
      '🎮 Join my DROPVOICE room!\nRoom Code: ${widget.roomCode}\n\nOpen DROPVOICE → Join Room → Enter code: ${widget.roomCode}',
      subject: 'DROPVOICE Room Invite',
    );
  }

  String get _connectionLabel => switch (_connectionState) {
    lk.ConnectionState.connected => 'CONNECTED',
    lk.ConnectionState.connecting => 'CONNECTING',
    lk.ConnectionState.reconnecting => 'RECONNECTING',
    lk.ConnectionState.disconnected => 'DISCONNECTED',
  };

  Color get _connectionColor => switch (_connectionState) {
    lk.ConnectionState.connected => Dv.green,
    lk.ConnectionState.connecting => Colors.amber,
    lk.ConnectionState.reconnecting => Colors.orange,
    lk.ConnectionState.disconnected => Dv.crimson,
  };

  @override
  void dispose() {
    _livekitService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) return const Scaffold(backgroundColor: Dv.obsidian, body: DvLoadingState(message: 'ESTABLISHING LINK...'));
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Dv.obsidian,
        body: DvErrorState(
          message: _errorMessage!,
          onRetry: () { setState(() { _errorMessage = null; _isConnecting = true; }); _connectToRoom(); },
          onBack: () => context.go('/home'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Dv.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Dv.s20, vertical: Dv.s16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Dv.steel))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TelemetryLabel(text: 'DROPVOICE', color: Dv.green),
                          const SizedBox(height: Dv.s4),
                          Text('ROOM', style: Dv.mono(size: 11, color: Dv.ash)),
                        ],
                      ),
                      StatusBadge(label: _connectionLabel, color: _connectionColor),
                    ],
                  ),
                  const SizedBox(height: Dv.s12),

                  // Room code row — ALWAYS VISIBLE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dv.s16, vertical: Dv.s12),
                    decoration: BoxDecoration(
                      color: Dv.charcoal,
                      borderRadius: BorderRadius.circular(Dv.r12),
                      border: Border.all(color: Dv.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tag_rounded, color: Dv.green, size: 18),
                        const SizedBox(width: Dv.s8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TelemetryLabel(text: 'ROOM CODE', color: Dv.ash),
                              const SizedBox(height: 2),
                              Text(widget.roomCode, style: Dv.monoLarge(size: 22)),
                            ],
                          ),
                        ),
                        // Copy button
                        GestureDetector(
                          onTap: _copyRoomCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: Dv.s12, vertical: Dv.s8),
                            decoration: BoxDecoration(
                              color: _codeCopied ? Dv.green.withValues(alpha: 0.2) : Dv.graphite,
                              borderRadius: BorderRadius.circular(Dv.r8),
                              border: Border.all(color: _codeCopied ? Dv.green : Dv.steel),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_codeCopied ? Icons.check_rounded : Icons.copy_rounded, size: 14, color: _codeCopied ? Dv.green : Dv.ash),
                                const SizedBox(width: 4),
                                Text(_codeCopied ? 'COPIED' : 'COPY', style: Dv.mono(size: 10, color: _codeCopied ? Dv.green : Dv.ash)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: Dv.s8),
                        // Share button
                        GestureDetector(
                          onTap: _shareRoom,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: Dv.s12, vertical: Dv.s8),
                            decoration: BoxDecoration(
                              color: Dv.graphite,
                              borderRadius: BorderRadius.circular(Dv.r8),
                              border: Border.all(color: Dv.steel),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.ios_share_rounded, size: 14, color: Dv.ash),
                                const SizedBox(width: 4),
                                Text('SHARE', style: Dv.mono(size: 10, color: Dv.ash)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Dv.s8),
                  TelemetryLabel(
                    text: '${_participants.length} PARTICIPANT${_participants.length == 1 ? '' : 'S'}',
                    color: Dv.ash,
                  ),
                ],
              ),
            ),

            // ── Participants ──
            Expanded(
              child: _participants.isEmpty
                  ? const DvEmptyState(icon: Icons.headset_off_rounded, title: 'AWAITING COMMS', subtitle: 'Waiting for others to join...')
                  : ListView.builder(
                      padding: const EdgeInsets.all(Dv.s20),
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final p = _participants[index];
                        return ParticipantCard(name: p.name, isLocal: p.isLocal, isSpeaking: p.isSpeaking, isMuted: p.isMuted);
                      },
                    ),
            ),

            // ── Controls ──
            Container(
              padding: const EdgeInsets.all(Dv.s24),
              decoration: const BoxDecoration(color: Dv.graphite, border: Border(top: BorderSide(color: Dv.steel))),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ControlButton(icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, isActive: !_isMuted, onPressed: _toggleMic, size: 64),
                    const SizedBox(width: Dv.s24),
                    ControlButton(icon: Icons.call_end_rounded, isActive: false, onPressed: _leaveRoom, size: 64),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
