import 'package:flutter/material.dart';

class ExpressionCard extends StatefulWidget {
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
  State<ExpressionCard> createState() => _ExpressionCardState();
}

class _ExpressionCardState extends State<ExpressionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 180.0 : 230.0;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.08),
            secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Floating decorative circles
          Positioned(
            top: 12,
            right: 16,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatController.value * 8 - 4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.4),
                          secondaryColor.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 12,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatController.value * 6 + 3),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondaryColor.withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 24,
            left: 20,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.25),
              ),
            ),
          ),
          // Main avatar
          Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              scale: widget.isListening ? 1.06 : 1.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                offset: widget.isListening ? const Offset(0, -0.03) : Offset.zero,
                child: Image.asset(
                  widget.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported_outlined, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan asset ekspresi',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (widget.isThinking)
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
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
    this.isLoading = false,
  });

  final String text;
  final bool fromUser;
  final DateTime timestamp;
  final ImageProvider? userAvatar;
  final String assistantAvatarAsset;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    
    final alignment = fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final maxWidth = MediaQuery.of(context).size.width * 0.68;
    final bubbleColor = fromUser
        ? null
        : theme.colorScheme.surface;
    final bubbleGradient = fromUser
        ? LinearGradient(
            colors: [
              primaryColor,
              secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final borderColor = fromUser
        ? null
        : primaryColor.withOpacity(0.2);
    final textColor = fromUser ? Colors.white : theme.colorScheme.onSurface;
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
                  color: primaryColor.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  const ThinkingChatIndicator()
                else
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.45,
                        ),
                  ),
                const SizedBox(height: 4),
                if (!isLoading)
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
                      fromUser ? primaryColor : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(3),
                  border: borderColor == null
                      ? null
                      : Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.08),
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

class ThinkingChatIndicator extends StatefulWidget {
  const ThinkingChatIndicator({super.key});

  @override
  State<ThinkingChatIndicator> createState() => _ThinkingChatIndicatorState();
}

class _ThinkingChatIndicatorState extends State<ThinkingChatIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            var value = (_controller.value - delay) % 1.0;
            if (value < 0) value += 1.0;

            final scale = value < 0.5 ? 1.0 + (value * 2) * 0.4 : 1.4 - ((value - 0.5) * 2) * 0.4;
            final opacity = value < 0.5 ? 0.4 + (value * 2) * 0.6 : 1.0 - ((value - 0.5) * 2) * 0.6;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 6),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.isActive,
    this.onTap,
  });

  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
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

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final baseColor = widget.isActive || _isPressed
        ? primaryColor
        : secondaryColor;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: 44,
        height: 44,
        color: Colors.transparent,
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
                    ? Border.all(color: primaryColor.withOpacity(0.7), width: 2)
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
    );
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: primaryColor,
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
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
