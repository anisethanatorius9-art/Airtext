import 'package:flutter/material.dart';

typedef VideoCallJoinCallback = Future<void> Function(
  BuildContext screenContext, {
  required bool microphoneMuted,
  required bool cameraDisabled,
});

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    required this.callerName,
    required this.onJoinCall,
    this.callerAvatar,
    super.key,
  });

  final String callerName;
  final String? callerAvatar;
  final VideoCallJoinCallback onJoinCall;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _microphoneMuted = false;
  bool _cameraDisabled = false;
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.callerName.trim().isEmpty
        ? 'Air app contact'
        : widget.callerName.trim();
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final avatarUrl = widget.callerAvatar;
    final hasAvatar = avatarUrl != null && avatarUrl.startsWith('http');

    return Scaffold(
      backgroundColor: const Color(0xFF0B1110),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1B3028),
                    Color(0xFF0B1110),
                    Color(0xFF080B0A),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close call screen',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      const Icon(Icons.lock_outline, size: 15),
                      const SizedBox(width: 7),
                      Text(
                        'AIRTEXT VIDEO',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 68,
                                backgroundColor: const Color(0xFF28463A),
                                backgroundImage: hasAvatar
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: hasAvatar
                                    ? null
                                    : Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Color(0xFFD8F0DF),
                                          fontSize: 38,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ready to join',
                                style: TextStyle(
                                  color: Color(0xFFB9E878),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your live video opens when you join the call.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFB0BBB4),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 22,
                        right: 18,
                        child: Container(
                          width: 88,
                          height: 126,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18211D),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF53635A)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _cameraDisabled
                                    ? Icons.videocam_off_rounded
                                    : Icons.person_outline_rounded,
                                color: Colors.white70,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CallSetupControl(
                            label: _microphoneMuted ? 'Unmute' : 'Mute',
                            tooltip: _microphoneMuted
                                ? 'Unmute microphone'
                                : 'Mute microphone',
                            icon: _microphoneMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            selected: _microphoneMuted,
                            onPressed: () => setState(
                              () => _microphoneMuted = !_microphoneMuted,
                            ),
                          ),
                          const SizedBox(width: 34),
                          _CallSetupControl(
                            label: _cameraDisabled ? 'Camera off' : 'Camera',
                            tooltip: _cameraDisabled
                                ? 'Turn camera on'
                                : 'Turn camera off',
                            icon: _cameraDisabled
                                ? Icons.videocam_off_rounded
                                : Icons.videocam_rounded,
                            selected: _cameraDisabled,
                            onPressed: () => setState(
                              () => _cameraDisabled = !_cameraDisabled,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _joining
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.call_end_rounded),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFFA7A0),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF70433F),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _joining ? null : _joinCall,
                              icon: _joining
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.video_call_rounded),
                              label: Text(_joining ? 'Joining' : 'Join call'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB9E878),
                                foregroundColor: const Color(0xFF101714),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Future<void> _joinCall() async {
    setState(() => _joining = true);
    try {
      await widget.onJoinCall(
        context,
        microphoneMuted: _microphoneMuted,
        cameraDisabled: _cameraDisabled,
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }
}

class _CallSetupControl extends StatelessWidget {
  const _CallSetupControl({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            fixedSize: const Size(56, 56),
            backgroundColor: selected
                ? const Color(0xFFB9E878)
                : const Color(0xFF26332D),
            foregroundColor: selected ? const Color(0xFF101714) : Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
