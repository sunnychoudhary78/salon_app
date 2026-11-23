import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/features/ai_stylist/data/models/ai_stylist_models.dart';
import 'package:saloon_booking/features/ai_stylist/presentation/providers/ai_stylist_provider.dart';
import 'package:saloon_booking/features/ai_stylist/presentation/widgets/face_analysis_card.dart';
import 'package:saloon_booking/features/ai_stylist/presentation/widgets/hairstyle_recommendation_carousel.dart';
import 'package:saloon_booking/features/ai_stylist/presentation/widgets/recommended_salons_strip.dart';
import 'package:saloon_booking/features/ai_stylist/presentation/widgets/tryon_preview_sheet.dart';

class AiStylistChatScreen extends ConsumerStatefulWidget {
  const AiStylistChatScreen({super.key});

  @override
  ConsumerState<AiStylistChatScreen> createState() =>
      _AiStylistChatScreenState();
}

class _AiStylistChatScreenState extends ConsumerState<AiStylistChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  static const _starterPrompts = [
    'Which low-maintenance haircut suits an oval face?',
    'Suggest the best hairstyle for a wedding or party look',
    'Best haircuts to cover a thinning hairline',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openMultiAngleScan() async {
    final result = await context.push<bool>(RoutePaths.customerAiScan);
    if (result == true) {
      _scrollToBottom();
    }
  }

  void _openTryOn(String analysisId, HairstyleRecommendation rec, {String? originalImageUrl}) {
    final state = ref.read(aiStylistProvider);
    final scanImageUrl = originalImageUrl ?? state.activeSession?.previewImageUrl;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TryOnPreviewSheet(
        analysisId: analysisId,
        recommendation: rec,
        originalImageUrl: scanImageUrl,
      ),
    );
  }

  void _openSessionsSheet() {
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(aiStylistProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Your Consultations',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(aiStylistProvider.notifier).startNewSession();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New Chat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No consultation history yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.sessions.length,
                        itemBuilder: (_, index) {
                          final session = state.sessions[index];
                          final isActive =
                              session.id == state.activeSession?.id;
                          return ListTile(
                            selected: isActive,
                            leading: Icon(
                              Icons.face_retouching_natural_rounded,
                              color: isActive ? colors.accent : colors.textMuted,
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: isActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: session.previewFaceShape != null
                                ? Text(
                                    '${session.previewFaceShape} Face',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: colors.textMuted,
                              ),
                              onPressed: () {
                                ref
                                    .read(aiStylistProvider.notifier)
                                    .deleteSession(session.id);
                              },
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              ref
                                  .read(aiStylistProvider.notifier)
                                  .selectSession(session.id);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendText([String? preset]) async {
    final text = preset ?? _messageController.text.trim();
    if (text.isEmpty) return;
    if (preset == null) _messageController.clear();
    _scrollToBottom();
    await ref.read(aiStylistProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final state = ref.watch(aiStylistProvider);

    ref.listen<AiStylistChatState>(aiStylistProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CATCHY AI Stylist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              state.activeSession?.title ?? 'Personal Hair & Look Advisor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Face Scan',
            onPressed: _openMultiAngleScan,
            icon: Icon(Icons.face_retouching_natural_rounded, color: colors.accent),
          ),
          IconButton(
            tooltip: 'Chat History',
            onPressed: _openSessionsSheet,
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(
                state.errorMessage!,
                style: TextStyle(color: colors.textPrimary, fontSize: 12),
              ),
              backgroundColor: colors.surfaceElevated,
              actions: [
                TextButton(
                  onPressed: () =>
                      ref.read(aiStylistProvider.notifier).initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: state.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                    ? _EmptyStylistWelcome(
                        onScanTap: _openMultiAngleScan,
                        starterPrompts: _starterPrompts,
                        onPromptTap: _sendText,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                        itemCount: state.messages.length +
                            (state.isSendingChat ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.messages.length) {
                            return _TypingIndicatorBubble();
                          }
                          final msg = state.messages[index];
                          return _ChatMessageTile(
                            message: msg,
                            onPromptTap: _sendText,
                            onTryOnTap: _openTryOn,
                          );
                        },
                      ),
          ),
          _ChatInputBar(
            controller: _messageController,
            isBusy: state.isSendingChat || state.isAnalyzing,
            onScanTap: _openMultiAngleScan,
            onSendTap: () => _sendText(),
          ),
        ],
      ),
    );
  }
}

class _EmptyStylistWelcome extends StatelessWidget {
  const _EmptyStylistWelcome({
    required this.onScanTap,
    required this.starterPrompts,
    required this.onPromptTap,
  });

  final VoidCallback onScanTap;
  final List<String> starterPrompts;
  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: colors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 32,
                  color: colors.onAccent,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Find the Perfect Hairstyle for Your Face Shape',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Front, Left, and Right angle photos. Our AI will analyze your jawline, forehead, and hair type to suggest the best cuts and nearby salons.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onScanTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text(
                    'Scan Face (Multi-Angle)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Or ask directly:',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...starterPrompts.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onPromptTap(p),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.glassBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessageTile extends StatelessWidget {
  const _ChatMessageTile({
    required this.message,
    required this.onPromptTap,
    required this.onTryOnTap,
  });

  final AiChatMessage message;
  final ValueChanged<String> onPromptTap;
  final void Function(String analysisId, HairstyleRecommendation rec)
      onTryOnTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isUser = message.isUser;
    final payload = message.cardPayload;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 6,
                children: message.imageUrls
                    .map(
                      (url) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: resolveImageUrl(url),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * (isUser ? 0.78 : 0.92),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isUser ? colors.primary : colors.surfaceElevated,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: !isUser ? const Radius.circular(4) : null,
              ),
              border: isUser ? null : Border.all(color: colors.glassBorder),
            ),
            child: Text(
              message.contentText,
              style: TextStyle(
                color: isUser ? colors.onPrimary : colors.textPrimary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
          if (!isUser && payload != null) ...[
            if (payload.faceProfile != null)
              FaceAnalysisCard(profile: payload.faceProfile!),
            if (payload.recommendations.isNotEmpty)
              HairstyleRecommendationCarousel(
                recommendations: payload.recommendations,
                analysisId: payload.analysisId ?? message.analysisId,
                onTryOnTap: (rec) {
                  final aid = payload.analysisId ?? message.analysisId;
                  if (aid != null) onTryOnTap(aid, rec);
                },
              ),
            if (payload.recommendedSalons.isNotEmpty)
              RecommendedSalonsStrip(salons: payload.recommendedSalons),
            if (payload.followUpQuestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: payload.followUpQuestions
                    .map(
                      (q) => ActionChip(
                        label: Text(
                          q,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => onPromptTap(q),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Stylist is thinking...',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.isBusy,
    required this.onScanTap,
    required this.onSendTap,
  });

  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onScanTap;
  final VoidCallback onSendTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Upload Face Angles',
              onPressed: isBusy ? null : onScanTap,
              icon: Icon(
                Icons.add_a_photo_rounded,
                color: colors.accent,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isBusy,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSendTap(),
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask about hairstyles, beard styles, or salons...',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.glassBorder),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: colors.accent,
              child: IconButton(
                onPressed: isBusy ? null : onSendTap,
                icon: Icon(Icons.send_rounded, color: colors.onAccent, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
