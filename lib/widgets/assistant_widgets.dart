import 'package:flutter/material.dart';

class ExpressionCard extends StatelessWidget {
  const ExpressionCard({
    super.key,
    required this.assetPath,
    required this.isThinking,
    required this.isListening,
    required this.compact,
  });

  final String assetPath;
  final bool isThinking;
  final bool isListening;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 180.0 : 230.0;
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              scale: isListening ? 1.06 : 1.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                offset: isListening ? const Offset(0, -0.03) : Offset.zero,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported_outlined, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan asset ekspresi',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (isThinking)
            const Positioned(
              right: 8,
              bottom: 8,
              child: ThinkingIndicator(),
            ),
        ],
      ),
    );
  }
}

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF35D9C).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.fromUser,
    required this.timestamp,
    this.userAvatar,
    this.assistantAvatarAsset = 'assets/bubble/avatar.jpeg',
  });

  final String text;
  final bool fromUser;
  final DateTime timestamp;
  final ImageProvider? userAvatar;
  final String assistantAvatarAsset;

  @override
  Widget build(BuildContext context) {
    final alignment = fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final maxWidth = MediaQuery.of(context).size.width * 0.68;
    final bubbleColor = fromUser
        ? null
        : const Color(0xFFFFF5F7);
    final bubbleGradient = fromUser
        ? const LinearGradient(
            colors: [
              Color(0xFFFFB7C5),
              Color(0xFFF35D9C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final borderColor = fromUser
        ? null
        : const Color(0xFFE0BBE4).withOpacity(0.4);
    final textColor = fromUser ? Colors.white : const Color(0xFF4A4A4A);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: Radius.circular(fromUser ? 24 : 8),
      bottomRight: Radius.circular(fromUser ? 8 : 24),
    );
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFFEFE7E4),
      backgroundImage: fromUser
          ? userAvatar
          : AssetImage(assistantAvatarAsset) as ImageProvider,
      child: fromUser
          ? (userAvatar == null
              ? const Icon(Icons.person, size: 16)
              : null)
          : null,
    );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 64),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              gradient: bubbleGradient,
              borderRadius: radius,
              border: borderColor == null ? null : Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fromUser
                            ? Colors.white.withOpacity(0.75)
                            : const Color(0xFF6B6460).withOpacity(0.75),
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          if (fromUser)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.22),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: fromUser ? -4 : null,
            left: fromUser ? null : -4,
            bottom: 10,
            child: Transform.rotate(
              angle: fromUser ? 0.55 : -0.55,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      fromUser ? const Color(0xFFF35D9C) : const Color(0xFFFFF5F7),
                  borderRadius: BorderRadius.circular(3),
                  border: borderColor == null
                      ? null
                      : Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: alignment,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.85 + (value * 0.15), // Scale from 0.85 to 1.0
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 12),
                child: child,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!fromUser) avatar,
              if (!fromUser) const SizedBox(width: 8),
              Flexible(child: bubble),
              if (fromUser) const SizedBox(width: 8),
              if (fromUser) avatar,
            ],
          ),
        ),
      ),
    );
  }
}

class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.isActive,
    this.onTap,
    this.onPressStart,
    this.onPressEnd,
  });

  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onPressStart;
  final VoidCallback? onPressEnd;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  OverlayEntry? _popupOverlay;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isActive || _isPressed
        ? const Color(0xFFF35D9C)
        : const Color(0xFFFFB7C5);
    return Listener(
      onPointerDown: (_) {
        setState(() => _isPressed = true);
        _showPopup(context);
        if (widget.onPressStart != null) widget.onPressStart!();
      },
      onPointerUp: (_) {
        setState(() => _isPressed = false);
        _removePopup();
        if (widget.onPressEnd != null) widget.onPressEnd!();
      },
      onPointerCancel: (_) {
        setState(() => _isPressed = false);
        _removePopup();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isActive)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.35);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: _isPressed
                      ? Border.all(color: Colors.pinkAccent, width: 2)
                      : null,
                ),
                child: Icon(
                  widget.isActive ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPopup(BuildContext context) {
    if (_popupOverlay != null) return;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    _popupOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 20,
        top: offset.dy - 60,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: _isPressed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                'Tahan untuk merekam',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_popupOverlay!);
  }

  void _removePopup() {
    _popupOverlay?.remove();
    _popupOverlay = null;
  }
}


class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPressStart: widget.onLongPressStart == null
          ? null
          : (_) => widget.onLongPressStart?.call(),
      onLongPressEnd: widget.onLongPressEnd == null
          ? null
          : (_) => widget.onLongPressEnd?.call(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  const SendButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFB7C5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white),
      ),
    );
  }
}

class StatusPill extends StatefulWidget {
  const StatusPill({super.key, required this.text});

  final String text;

  @override
  State<StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<StatusPill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant StatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.text.isEmpty ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB7C5).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.text,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class GlowBlob extends StatelessWidget {
  const GlowBlob({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
