import 'package:flutter/material.dart';

import '../../../../data/models/rich_text_document.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

class RichTextDocumentView extends StatelessWidget {
  const RichTextDocumentView({super.key, required this.document});

  final RichTextDocument document;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final RichTextBlock block in document.blocks)
          KeyedSubtree(
            key: ValueKey<String>(block.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: RichTextBlockRenderer(block: block),
            ),
          ),
      ],
    );
  }
}

class RichTextBlockRenderer extends StatelessWidget {
  const RichTextBlockRenderer({super.key, required this.block});

  final RichTextBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.isHeading) {
      return HeadingBlock(block: block);
    }
    if (block.isBulletList) {
      return BulletListBlock(block: block);
    }
    if (block.isOrderedList) {
      return OrderedListBlock(block: block);
    }
    if (block.isQuote) {
      return QuoteBlock(block: block);
    }
    return ParagraphBlock(block: block);
  }
}

class ParagraphBlock extends StatelessWidget {
  const ParagraphBlock({super.key, required this.block});

  final RichTextBlock block;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      buildMarkedSpan(
        context,
        block.text,
        block.marks,
        AppTypography.body(context).copyWith(height: 1.7, fontSize: 18),
      ),
    );
  }
}

class HeadingBlock extends StatelessWidget {
  const HeadingBlock({super.key, required this.block});

  final RichTextBlock block;

  @override
  Widget build(BuildContext context) {
    final int level = (block.level ?? 1).clamp(1, 3);
    final double size = level == 1 ? 28 : (level == 2 ? 24 : 20);
    return Text.rich(
      buildMarkedSpan(
        context,
        block.text,
        block.marks,
        AppTypography.bookTitle(context, fontSize: size).copyWith(height: 1.3),
      ),
    );
  }
}

class QuoteBlock extends StatelessWidget {
  const QuoteBlock({super.key, required this.block});

  final RichTextBlock block;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Text.rich(
          buildMarkedSpan(
            context,
            block.text,
            block.marks,
            AppTypography.body(context).copyWith(
              height: 1.7,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondaryFor(Theme.of(context).brightness),
            ),
          ),
        ),
      ),
    );
  }
}

class BulletListBlock extends StatelessWidget {
  const BulletListBlock({super.key, required this.block});

  final RichTextBlock block;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final RichTextListItem item in block.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: AppTypography.body(context).copyWith(height: 1.7)),
                Expanded(
                  child: Text(
                    item.text,
                    style: AppTypography.body(context).copyWith(height: 1.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class OrderedListBlock extends StatelessWidget {
  const OrderedListBlock({super.key, required this.block});

  final RichTextBlock block;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < block.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}.',
                    style: AppTypography.body(context).copyWith(height: 1.7),
                  ),
                ),
                Expanded(
                  child: Text(
                    block.items[i].text,
                    style: AppTypography.body(context).copyWith(height: 1.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

TextSpan buildMarkedSpan(
  BuildContext context,
  String text,
  List<RichTextMark> marks,
  TextStyle base,
) {
  if (text.isEmpty) return TextSpan(text: '', style: base);
  if (marks.isEmpty) return TextSpan(text: text, style: base);

  final int length = text.length;
  final List<TextSpan> spans = <TextSpan>[];
  int index = 0;
  while (index < length) {
    bool bold = false;
    bool italic = false;
    for (final RichTextMark mark in marks) {
      if (index >= mark.start && index < mark.end) {
        if (mark.isBold) bold = true;
        if (mark.isItalic) italic = true;
      }
    }
    int end = index + 1;
    while (end < length) {
      bool nextBold = false;
      bool nextItalic = false;
      for (final RichTextMark mark in marks) {
        if (end >= mark.start && end < mark.end) {
          if (mark.isBold) nextBold = true;
          if (mark.isItalic) nextItalic = true;
        }
      }
      if (nextBold != bold || nextItalic != italic) break;
      end++;
    }
    spans.add(
      TextSpan(
        text: text.substring(index, end),
        style: base.copyWith(
          fontWeight: bold ? FontWeight.w700 : base.fontWeight,
          fontStyle: italic ? FontStyle.italic : base.fontStyle,
        ),
      ),
    );
    index = end;
  }
  return TextSpan(style: base, children: spans);
}
