import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../data/assistant_providers.dart';

class InventoryAssistantScreen extends ConsumerStatefulWidget {
  const InventoryAssistantScreen({super.key});

  @override
  ConsumerState<InventoryAssistantScreen> createState() =>
      _InventoryAssistantScreenState();
}

class _InventoryAssistantScreenState
    extends ConsumerState<InventoryAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'Which products are running low?',
    'What was scanned today?',
    'Which brands are used most often?',
    'Summarize my inventory',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final question = text ?? _controller.text;
    _controller.clear();
    await ref.read(assistantChatControllerProvider.notifier).send(question);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(assistantChatControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: const [
          IconButton(
            tooltip: 'Voice input placeholder',
            onPressed: null,
            icon: Icon(Icons.mic_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_suggestions[index]),
                  onPressed:
                      chat.isLoading ? null : () => _send(_suggestions[index]),
                ),
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemCount: _suggestions.length,
              ),
            ),
            Expanded(
              child: chat.messages.isEmpty
                  ? const _AssistantEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount:
                          chat.messages.length + (chat.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= chat.messages.length) {
                          return const _TypingIndicator();
                        }
                        final message = chat.messages[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: Align(
                            alignment: message.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.78),
                              margin:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: message.isUser
                                    ? AppColors.primaryGradient
                                    : null,
                                color:
                                    message.isUser ? null : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                boxShadow: message.isUser
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.07),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                              ),
                              child: Text(
                                message.content,
                                style: TextStyle(
                                  color: message.isUser
                                      ? Colors.white
                                      : AppColors.ink,
                                  height: 1.35,
                                  fontWeight: message.isUser
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (chat.errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  chat.errorMessage!,
                  style: const TextStyle(color: AppColors.rose),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask about scans or inventory',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    AnimatedScale(
                      scale: chat.isLoading ? 0.92 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: IconButton.filled(
                        tooltip: 'Send',
                        onPressed: chat.isLoading ? null : () => _send(),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ),
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

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 42),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ask about inventory',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Answers use saved scan and inventory context only.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final value =
                    ((_controller.value + index * 0.22) % 1.0).clamp(0.0, 1.0);
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color:
                        AppColors.indigo.withValues(alpha: 0.28 + value * 0.64),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
