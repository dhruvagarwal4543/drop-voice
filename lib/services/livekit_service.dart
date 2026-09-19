// ignore_for_file: avoid_print
import 'dart:async';
import 'package:flutter_background/flutter_background.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../core/errors/app_exception.dart';
import '../models/participant.dart' as model;

/// Wraps the LiveKit Room and exposes streams for the UI.
/// ALL participant state is driven by real LiveKit events.
/// Nothing is faked or hardcoded here.
class LiveKitService {
  LiveKitService();

  lk.Room? _room;

  // State streams
  final _participantsController =
      StreamController<List<model.Participant>>.broadcast();
  final _connectionStateController =
      StreamController<lk.ConnectionState>.broadcast();

  Stream<List<model.Participant>> get participantsStream =>
      _participantsController.stream;
  Stream<lk.ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Current connection state.
  lk.ConnectionState get connectionState =>
      _room?.connectionState ?? lk.ConnectionState.disconnected;

  /// Whether connected.
  bool get isConnected =>
      _room?.connectionState == lk.ConnectionState.connected;

  /// Local mic muted?
  bool get isMicMuted {
    final pub = _room?.localParticipant?.isMicrophoneEnabled();
    return pub != true;
  }

  // LiveKit event subscriptions
  final List<lk.EventsListener<lk.RoomEvent>> _listeners = [];

  /// Connects to LiveKit and publishes microphone.
  Future<void> connect({
    required String url,
    required String token,
  }) async {
    try {
      // Enable background execution for Android 14+
      try {
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "DROPVOICE",
          notificationText: "Voice chat is active.",
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        );
        await FlutterBackground.initialize(androidConfig: androidConfig);
        await FlutterBackground.enableBackgroundExecution();
      } catch (e) {
        print('[AUDIO] Failed to enable background execution: $e');
      }

      _room = lk.Room(
        roomOptions: const lk.RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioCaptureOptions: lk.AudioCaptureOptions(
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
          ),
        ),
      );

      print('[AUDIO] session initialized');

      // Force audio to speakerphone instead of earpiece
      // ignore: deprecated_member_use
      await lk.Hardware.instance.setSpeakerphoneOn(true);
      print('[AUDIO] output route = speaker');

      // Wire event listeners before connecting.
      _attachListeners(_room!);

      await _room!.connect(url, token);

      // Publish microphone only — no video, no screen share.
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      print('[AUDIO] microphone track created / published');

      _emitParticipants();
    } on VoiceException {
      rethrow;
    } catch (e) {
      throw VoiceException('Failed to connect to LiveKit: $e');
    }
  }

  /// Toggle local microphone mute state.
  Future<void> toggleMicrophone() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final current = local.isMicrophoneEnabled();
    await local.setMicrophoneEnabled(!current);
    _emitParticipants();
  }

  /// Disconnect and clean up.
  Future<void> disconnect() async {
    await _room?.disconnect();
    try {
      await FlutterBackground.disableBackgroundExecution();
    } catch (e) {
      print('[AUDIO] Failed to disable background: $e');
    }
    _cleanup();
  }

  void _attachListeners(lk.Room room) {
    final listener = room.createListener();
    _listeners.add(listener);

    listener
      ..on<lk.RoomConnectedEvent>((event) {
        _connectionStateController.add(lk.ConnectionState.connected);
        _emitParticipants();
      })
      ..on<lk.RoomDisconnectedEvent>((event) {
        _connectionStateController.add(lk.ConnectionState.disconnected);
        _emitParticipants();
      })
      ..on<lk.RoomReconnectingEvent>((event) {
        _connectionStateController.add(lk.ConnectionState.reconnecting);
      })
      ..on<lk.RoomReconnectedEvent>((event) {
        _connectionStateController.add(lk.ConnectionState.connected);
        _emitParticipants();
      })
      ..on<lk.ParticipantConnectedEvent>((event) {
        _emitParticipants();
      })
      ..on<lk.ParticipantDisconnectedEvent>((event) {
        _emitParticipants();
      })
      ..on<lk.TrackPublishedEvent>((event) {
        _emitParticipants();
      })
      ..on<lk.TrackUnpublishedEvent>((event) {
        _emitParticipants();
      })
      ..on<lk.TrackSubscribedEvent>((event) {
        if (event.track is lk.AudioTrack) {
          print('[AUDIO] remote audio subscribed from ${event.participant.identity}');
        }
        _emitParticipants();
      })
      ..on<lk.TrackUnsubscribedEvent>((event) {
        _emitParticipants();
      })
      ..on<lk.ActiveSpeakersChangedEvent>((event) {
        _emitParticipants();
      })
      ..on<lk.TrackMutedEvent>((event) {
        _emitParticipants();
      })
      ..on<lk.TrackUnmutedEvent>((event) {
        _emitParticipants();
      });
  }

  void _emitParticipants() {
    final room = _room;
    if (room == null) {
      _participantsController.add([]);
      return;
    }

    final participants = <model.Participant>[];

    // Local participant
    final local = room.localParticipant;
    if (local != null) {
      participants.add(model.Participant(
        identity: local.identity,
        name: local.name.isNotEmpty ? local.name : local.identity,
        isLocal: true,
        isSpeaking: local.isSpeaking,
        isMuted: !local.isMicrophoneEnabled(),
      ));
    }

    // Remote participants — driven purely by LiveKit events.
    for (final remote in room.remoteParticipants.values) {
      participants.add(model.Participant(
        identity: remote.identity,
        name: remote.name.isNotEmpty ? remote.name : remote.identity,
        isLocal: false,
        isSpeaking: remote.isSpeaking,
        isMuted: !remote.isMicrophoneEnabled(),
      ));
    }

    _participantsController.add(participants);
  }

  void _cleanup() {
    for (final l in _listeners) {
      l.dispose();
    }
    _listeners.clear();
    _room = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _participantsController.close();
    await _connectionStateController.close();
  }
}
