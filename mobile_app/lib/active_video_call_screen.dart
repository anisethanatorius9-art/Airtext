import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'airtext_call_client.dart';

class ActiveVideoCallScreen extends StatefulWidget {
  const ActiveVideoCallScreen({
    required this.callClient,
    required this.callId,
    required this.contactName,
    required this.isCaller,
    required this.startMuted,
    required this.startCameraOff,
    super.key,
  });

  final AirTextCallClient callClient;
  final String callId;
  final String contactName;
  final bool isCaller;
  final bool startMuted;
  final bool startCameraOff;

  @override
  State<ActiveVideoCallScreen> createState() => _ActiveVideoCallScreenState();
}

class _ActiveVideoCallScreenState extends State<ActiveVideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final Stopwatch _duration = Stopwatch();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription<AirTextCallSignal>? _signalSubscription;
  Timer? _durationTimer;
  Timer? _callStatusTimer;
  final List<RTCIceCandidate> _pendingCandidates = [];
  final List<AirTextCallSignal> _pendingSignals = [];
  bool _microphoneMuted = false;
  bool _cameraDisabled = false;
  bool _speakerOn = true;
  bool _isConnected = false;
  bool _isEnding = false;
  bool _offerSent = false;
  String _status = 'Connecting';

  @override
  void initState() {
    super.initState();
    _microphoneMuted = widget.startMuted;
    _cameraDisabled = widget.startCameraOff;
    _signalSubscription = widget.callClient.signals.listen(_handleSignal);
    unawaited(_initializeMedia());
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.contactName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFF090E0C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_remoteRenderer.srcObject != null)
            RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF20342A), Color(0xFF0A100D)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundColor: const Color(0xFF315441),
                      child: Text(
                        initials.isEmpty ? '?' : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _status,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'AIRTEXT CALL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _isConnected ? _formattedDuration : _status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.contactName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 86,
                        height: 132,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFF18211D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white30),
                        ),
                        child:
                            _localRenderer.srcObject != null && !_cameraDisabled
                            ? RTCVideoView(
                                _localRenderer,
                                mirror: true,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.videocam_off_rounded,
                                  color: Colors.white70,
                                  size: 28,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      _ControlButton(
                        icon: _speakerOn
                            ? Icons.volume_up_rounded
                            : Icons.hearing_rounded,
                        label: 'Speaker',
                        selected: _speakerOn,
                        onPressed: _toggleSpeaker,
                      ),
                      _ControlButton(
                        icon: Icons.flip_camera_ios_rounded,
                        label: 'Flip',
                        onPressed: _switchCamera,
                      ),
                      _ControlButton(
                        icon: _microphoneMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: _microphoneMuted ? 'Unmute' : 'Mute',
                        selected: _microphoneMuted,
                        onPressed: _toggleMicrophone,
                      ),
                      _ControlButton(
                        icon: _cameraDisabled
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        label: _cameraDisabled ? 'Camera off' : 'Camera',
                        selected: _cameraDisabled,
                        onPressed: _toggleCamera,
                      ),
                      _ControlButton(
                        icon: Icons.call_end_rounded,
                        label: 'End',
                        destructive: true,
                        onPressed: _endCall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedDuration {
    final elapsed = _duration.elapsed;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _initializeMedia() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      final iceServers = await widget.callClient.getIceServers();
      _peerConnection = await createPeerConnection({'iceServers': iceServers});
      await Helper.setSpeakerphoneOn(_speakerOn);
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate == null) return;
        unawaited(
          widget.callClient.sendSignal(widget.callId, 'ice-candidate', {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }),
        );
      };
      _peerConnection!.onTrack = (event) {
        if (!mounted || event.streams.isEmpty) return;
        setState(() {
          _remoteRenderer.srcObject = event.streams.first;
          _isConnected = true;
          _status = 'Connected';
        });
        _startDuration();
      };
      _peerConnection!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (!mounted) return;
          setState(() {
            _isConnected = true;
            _status = 'Connected';
          });
          _startDuration();
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          if (mounted) setState(() => _status = 'Connection failed');
        }
      };

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user', 'width': 720, 'height': 1280},
      });
      _localRenderer.srcObject = _localStream;
      for (final track in _localStream!.getTracks()) {
        if (track.kind == 'audio') track.enabled = !_microphoneMuted;
        if (track.kind == 'video') track.enabled = !_cameraDisabled;
        await _peerConnection!.addTrack(track, _localStream!);
      }
      if (mounted) {
        setState(() => _status = 'Waiting for ${widget.contactName}');
      }

      final pendingSignals = List<AirTextCallSignal>.of(_pendingSignals);
      _pendingSignals.clear();
      for (final signal in pendingSignals) {
        await _handleSignal(signal);
      }
      if (widget.isCaller && !_offerSent) _watchCallStatus();
    } catch (_) {
      if (mounted) setState(() => _status = 'Camera or microphone unavailable');
    }
  }

  Future<void> _handleSignal(AirTextCallSignal signal) async {
    if (signal.callId != widget.callId) return;
    if (_peerConnection == null || _localStream == null) {
      _pendingSignals.add(signal);
      return;
    }
    try {
      switch (signal.kind) {
        case 'accepted':
          if (widget.isCaller) {
            await _createOffer();
          }
        case 'offer':
          if (widget.isCaller) return;
          await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(
              signal.payload['sdp'] as String?,
              signal.payload['type'] as String?,
            ),
          );
          await _flushCandidates();
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          await widget.callClient.sendSignal(widget.callId, 'answer', {
            'type': answer.type,
            'sdp': answer.sdp,
          });
        case 'answer':
          if (!widget.isCaller) return;
          await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(
              signal.payload['sdp'] as String?,
              signal.payload['type'] as String?,
            ),
          );
          await _flushCandidates();
        case 'ice-candidate':
          final candidate = RTCIceCandidate(
            signal.payload['candidate'] as String?,
            signal.payload['sdpMid'] as String?,
            signal.payload['sdpMLineIndex'] as int?,
          );
          final remoteDescription = await _peerConnection
              ?.getRemoteDescription();
          if (remoteDescription == null) {
            _pendingCandidates.add(candidate);
          } else {
            await _peerConnection?.addCandidate(candidate);
          }
        case 'declined':
        case 'missed':
        case 'ended':
          if (mounted && !_isEnding) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Call connection interrupted');
    }
  }

  void _watchCallStatus() {
    _callStatusTimer?.cancel();
    _callStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _offerSent) {
        _callStatusTimer?.cancel();
        return;
      }
      try {
        final response = await widget.callClient.getCall(widget.callId);
        final status = (response['data'] as Map<String, dynamic>)['status'];
        if (status == 'accepted') {
          await _createOffer();
          _callStatusTimer?.cancel();
        } else if (status == 'declined' ||
            status == 'missed' ||
            status == 'ended') {
          _callStatusTimer?.cancel();
          if (mounted) Navigator.pop(context);
        }
      } catch (_) {
        if (mounted) setState(() => _status = 'Reconnecting');
      }
    });
  }

  Future<void> _createOffer() async {
    if (_offerSent || _peerConnection == null) return;
    _offerSent = true;
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    await widget.callClient.sendSignal(widget.callId, 'offer', {
      'type': offer.type,
      'sdp': offer.sdp,
    });
  }

  Future<void> _flushCandidates() async {
    final peerConnection = _peerConnection;
    if (peerConnection == null) return;
    for (final candidate in _pendingCandidates) {
      await peerConnection.addCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  void _startDuration() {
    if (_duration.isRunning) return;
    _duration.start();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleMicrophone() {
    setState(() => _microphoneMuted = !_microphoneMuted);
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !_microphoneMuted;
    }
  }

  void _toggleCamera() {
    setState(() => _cameraDisabled = !_cameraDisabled);
    for (final track
        in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !_cameraDisabled;
    }
  }

  Future<void> _switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await Helper.setSpeakerphoneOn(_speakerOn);
  }

  Future<void> _endCall() async {
    if (_isEnding) return;
    _isEnding = true;
    try {
      await widget.callClient.endCall(widget.callId);
    } catch (_) {
      // End the local media even if the signaling server is unreachable.
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callStatusTimer?.cancel();
    _signalSubscription?.cancel();
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      unawaited(track.stop());
    }
    unawaited(_localStream?.dispose());
    unawaited(_peerConnection?.close());
    unawaited(_localRenderer.dispose());
    unawaited(_remoteRenderer.dispose());
    super.dispose();
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final background = destructive
        ? const Color(0xFFC83E42)
        : selected
        ? const Color(0xFFB9E878)
        : const Color(0xFF27332D);
    final foreground = selected && !destructive
        ? const Color(0xFF101714)
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            fixedSize: const Size(56, 56),
            backgroundColor: background,
            foregroundColor: foreground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
