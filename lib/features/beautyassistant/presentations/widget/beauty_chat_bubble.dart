import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/beautyassistant/data/models/beauty_chat_models.dart';
import 'package:saloon_booking/features/beautyassistant/presentations/widget/beauty_assistant_style.dart';

class BeautyChatBubble extends StatelessWidget {
  const BeautyChatBubble({super.key, required this.message});

  final BeautyChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isUser = message.role == BeautyMessageRole.user;

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * (isUser ? 0.78 : 0.70),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 9),
        decoration: BoxDecoration(
          color: isUser ? colors.accent : colors.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          border: isUser ? null : Border.all(color: colors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: TextStyle(
                color: isUser ? colors.onAccent : colors.textPrimary,
                height: 1.5,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                TimeOfDay.fromDateTime(message.createdAt).format(context),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isUser
                      ? colors.onAccent.withValues(alpha: 0.72)
                      : colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BeautyAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'Stylist',
                    style: beautySerif(
                      context,
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: colors.accent,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                bubble,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small ringed avatar used next to assistant messages.
class BeautyAvatar extends StatelessWidget {
  const BeautyAvatar({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.accentSoft,
        border: Border.all(color: colors.accent.withValues(alpha: 0.5)),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.52,
        color: colors.accent,
      ),
    );
  }
}