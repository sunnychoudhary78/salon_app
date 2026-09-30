import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/beautyassistant/data/providers/beauty_assistant_provider.dart';
import 'package:saloon_booking/features/beautyassistant/presentations/widget/beauty_assistant_style.dart';
import 'package:saloon_booking/features/beautyassistant/presentations/widget/beauty_chat_bubble.dart';
import 'package:saloon_booking/features/beautyassistant/presentations/widget/beauty_recommadtion.dart';
import 'package:saloon_booking/features/beautyassistant/presentations/widget/beauty_suggestion.dart';

class BeautyAssistantScreen extends ConsumerStatefulWidget {
  const BeautyAssistantScreen({super.key});

  @override
  ConsumerState<BeautyAssistantScreen> createState() =>
      _BeautyAssistantScreenState();
}

class _BeautyAssistantScreenState extends ConsumerState<BeautyAssistantScreen> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestion]) async {
    final text = (suggestion ?? _inputController.text).trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _inputFocus.unfocus();
    await ref.read(beautyAssistantProvider.notifier).sendMessage(text);
    if (mounted) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _browseSalons() => context.go(RoutePaths.customerHome);

  void _showAbout() {
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BeautyAvatar(size: 44),
              const SizedBox(height: 16),
              Text(
                'Your personal beauty guide',
                style: beautySerif(
                  context,
                  size: 22,
                  weight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Get ideas for beauty, style, and grooming services. Recommendations are style suggestions only.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(beautyAssistantProvider);
    final colors = context.appColors;
    ref.listen(beautyAssistantProvider, (previous, next) {
      if (next.messages.length != previous?.messages.length ||
          next.isLoading != previous?.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Beauty Assistant',
              style: beautySerif(
                context,
                size: 20,
                weight: FontWeight.w700,
                color: colors.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'YOUR PERSONAL STYLIST',
              style: TextStyle(
                fontSize: 9.5,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About Beauty Assistant',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showAbout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.accent.withValues(alpha: 0),
                  colors.accent.withValues(alpha: 0.55),
                  colors.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount:
                  conversation.messages.length +
                  (conversation.messages.isEmpty ? 1 : 0) +
                  (conversation.isLoading ? 1 : 0) +
                  (conversation.errorMessage != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (conversation.messages.isEmpty && index == 0) {
                  return _WelcomeContent(onSuggestion: (value) => _send(value));
                }
                if (index < conversation.messages.length) {
                  final message = conversation.messages[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BeautyChatBubble(message: message),
                      if (message.recommendations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 6,
                            bottom: 14,
                            left: 40,
                          ),
                          child: SizedBox(
                            height: 214,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: message.recommendations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) =>
                                  BeautyRecommendationCard(
                                    index: i,
                                    recommendation: message.recommendations[i],
                                    onBrowseSalons: _browseSalons,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
                final offset = index - conversation.messages.length;
                if (conversation.isLoading && offset == 0) {
                  return const _TypingIndicator();
                }
                return _RetryNotice(
                  message: conversation.errorMessage!,
                  onRetry: () =>
                      ref.read(beautyAssistantProvider.notifier).retry(),
                );
              },
            ),
          ),
          _InputBar(
            controller: _inputController,
            focusNode: _inputFocus,
            isLoading: conversation.isLoading,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSend(),
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask about a look or service…',
                        hintStyle: TextStyle(color: colors.textMuted),
                        counterText: '',
                        filled: true,
                        fillColor: colors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: colors.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(
                            color: colors.accent.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Send message',
                    style: IconButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      disabledBackgroundColor: colors.accent.withValues(
                        alpha: 0.5,
                      ),
                      fixedSize: const Size(48, 48),
                    ),
                    onPressed: isLoading ? null : onSend,
                    icon: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onAccent,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Style and grooming suggestions only — not medical advice.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({required this.onSuggestion});
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ringed monogram
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.accent.withValues(alpha: 0.45)),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accentSoft,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colors.accent,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hello, I’m your\nbeauty assistant',
            style: beautySerif(
              context,
              size: 30,
              weight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tell me what you’re getting ready for or the style you have in mind. I’ll suggest beauty, hair, and grooming services at CATCHY salons.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Text(
                'TRY ASKING',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 1, color: colors.glassBorder)),
            ],
          ),
          const SizedBox(height: 14),
          BeautySuggestionChips(onSelected: onSuggestion),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const BeautyAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              border: Border.all(color: colors.glassBorder),
            ),
            child: const _BouncingDots(),
          ),
        ],
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (_controller.value - i * 0.18) % 1.0;
          final wave = t < 0.5 ? t * 2 : (1 - t) * 2; // 0 → 1 → 0
          return Container(
            margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
            width: 7,
            height: 7,
            transform: Matrix4.translationValues(0, -3 * wave, 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.35 + 0.65 * wave),
            ),
          );
        }),
      ),
    );
  }
}

class _RetryNotice extends StatelessWidget {
  const _RetryNotice({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final error = Theme.of(context).colorScheme.error;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: colors.accent),
          ),
        ],
      ),
    );
  }
}


