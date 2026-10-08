import 'package:flutter/material.dart';

import '../../../../core/config/reader_content_features.dart';
import '../../../../data/models/rich_text_document.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import 'reader_inline_image.dart';

/// Typography for rendered chapter content. Colors left null follow the
/// ambient theme.
class ReadingStyle {
  const ReadingStyle({
    this.fontSize = 18,
    this.lineHeight = 1.7,
    this.textColor,
    this.secondaryColor,
    this.accentColor,
    this.fontFamily,
    this.fontFamilyFallback,
    this.boldWeight = FontWeight.w700,
  });

  final double fontSize;
  final double lineHeight;
  final Color? textColor;
  final Color? secondaryColor;
  final Color? accentColor;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final FontWeight boldWeight;

  /// Space after each block, proportional to the text size.
  double get blockSpacing => fontSize * 0.95;

  TextStyle body(BuildContext context) {
    return AppTypography.body(context).copyWith(
      fontSize: fontSize,
      height: lineHeight,
      color: textColor,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      letterSpacing: 0.1,
    );
  }

  TextStyle heading(BuildContext context, int level) {
    final double scale = level == 1 ? 1.55 : (level == 2 ? 1.33 : 1.15);
    return AppTypography.bookTitle(
      context,
      fontSize: fontSize * scale,
      color: textColor,
    ).copyWith(height: 1.35);
  }

  Color secondary(BuildContext context) =>
      secondaryColor ??
      AppColors.textSecondaryFor(Theme.of(context).brightness);

  Color accent(BuildContext context) =>
      accentColor ?? Theme.of(context).colorScheme.primary;
}

/// Blocks of [document] the Reader shows, in order: every text block, and
/// media blocks whose type is enabled in [features].
List<RichTextBlock> visibleBlocks(
  RichTextDocument document, {
  ReaderContentFeatures features = ReaderContentFeatures.current,
}) {
  return document.blocks
      .where((RichTextBlock block) => isVisibleBlock(block, features))
      .toList(growable: false);
}

bool isVisibleBlock(RichTextBlock block, ReaderContentFeatures features) {
  return switch (block.media) {
    RichTextImage() => features.readerImageSupport,
    RichTextAudio() => features.readerAudioSupport,
    RichTextVideo() => features.readerVideoSupport,
    null => block.isText,
  };
}

/// Key for the block at [index]; falls back to the position when the
/// backend sent no id.
Key richTextBlockKey(RichTextBlock block, int index) =>
    ValueKey<String>(block.id.isEmpty ? 'blk-index-$index' : block.id);

class RichTextDocumentView extends StatelessWidget {
  const RichTextDocumentView({
    super.key,
    required this.document,
    this.style = const ReadingStyle(),
    this.features = ReaderContentFeatures.current,
  });

  final RichTextDocument document;
  final ReadingStyle style;
  final ReaderContentFeatures features;

  @override
  Widget build(BuildContext context) {
    final List<RichTextBlock> blocks =
        visibleBlocks(document, features: features);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < blocks.length; i++)
          RichTextBlockItem(
            key: richTextBlockKey(blocks[i], i),
            block: blocks[i],
            style: style,
          ),
      ],
    );
  }
}

/// One block with the spacing around it, for column or lazy-list layouts.
class RichTextBlockItem extends StatelessWidget {
  const RichTextBlockItem({
    super.key,
    required this.block,
    this.style = const ReadingStyle(),
  });

  final RichTextBlock block;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    final double spacing = style.blockSpacing;
    final EdgeInsets padding;
    if (block.isHeading) {
      padding = EdgeInsets.only(top: spacing * 0.5, bottom: spacing * 0.6);
    } else if (block.isMedia) {
      padding = EdgeInsets.only(top: spacing * 0.4, bottom: spacing * 1.4);
    } else {
      padding = EdgeInsets.only(bottom: spacing);
    }
    return Padding(
      padding: padding,
      child: RichTextBlockRenderer(block: block, style: style),
    );
  }
}

class RichTextBlockRenderer extends StatelessWidget {
  const RichTextBlockRenderer({
    super.key,
    required this.block,
    this.style = const ReadingStyle(),
  });

  final RichTextBlock block;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    final RichTextImage? image = block.image;
    if (image != null) {
      return ReaderInlineImage(image: image, style: style);
    }
    if (block.isMedia || !block.isKnownType) {
      // Audio and video have no renderer in this release.
      return const SizedBox.shrink();
    }
    if (block.isHeading) {
      return HeadingBlock(block: block, style: style);
    }
    if (block.isBulletList) {
      return BulletListBlock(block: block, style: style);
    }
    if (block.isOrderedList) {
      return OrderedListBlock(block: block, style: style);
    }
    if (block.isQuote) {
      return QuoteBlock(block: block, style: style);
    }
    return ParagraphBlock(block: block, style: style);
  }
}

class ParagraphBlock extends StatelessWidget {
  const ParagraphBlock({
    super.key,
    required this.block,
    this.style = const ReadingStyle(),
  });

  final RichTextBlock block;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      buildMarkedSpan(
        context,
        block.text,
        block.marks,
        style.body(context),
        boldWeight: style.boldWeight,
      ),
    );
  }
}

class HeadingBlock extends StatelessWidget {
  const HeadingBlock({
    super.key,
    required this.block,
    this.style = const ReadingStyle(),
  });

  final RichTextBlock block;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    final int level = (block.level ?? 1).clamp(1, 3);
    return Semantics(
      header: true,
      child: Text.rich(
        buildMarkedSpan(
          context,
          block.text,
          block.marks,
          style.heading(context, level),
          boldWeight: style.boldWeight,
        ),
      ),
    );
  }
}

class QuoteBlock extends StatelessWidget {
  const QuoteBlock({
    super.key,
    required this.block,
    this.style = const ReadingStyle(),
  });

  final RichTextBlock block;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: style.accent(context).withOpacity(0.7),
            width: 2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: Text.rich(
          buildMarkedSpan(
            context,
            block.text,
            block.marks,
            style.body(context).copyWith(
                  fontStyle: FontStyle.italic,
                  color: style.secondary(context),
                ),
            boldWeight: style.boldWeight,
          ),
        ),
      ),
    );
  }
}

class BulletListBlock extends StatelessWidget {
  const BulletListBlock({
    super.key,
    required this.block,
    this.style = const ReadingStyle(),
  });

  final RichTextBlock block;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    final TextStyle text = style.body(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final RichTextListItem item in block.items)
          Padding(
            padding: EdgeInsets.only(bottom: style.fontSize * 0.45),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: style.fontSize * 1.4,
                  child: Text(
                    '•',
                    style: text.copyWith(color: style.accent(context)),
                  ),
                ),
                Expanded(child: Text(item.text, style: text)),
              ],
            ),
          ),
      ],
    );
  }
}

class OrderedListBlock extends StatelessWidget {
  const OrderedListBlock({
    super.key,
    required this.block,
    this.style = const ReadingStyle(),
  });

  final RichTextBlock block;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    final TextStyle text = style.body(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < block.items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: style.fontSize * 0.45),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: style.fontSize * 1.9,
                  child: Text(
                    '${i + 1}.',
                    style: text.copyWith(color: style.accent(context)),
                  ),
                ),
                Expanded(child: Text(block.items[i].text, style: text)),
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
  TextStyle base, {
  FontWeight boldWeight = FontWeight.w700,
}) {
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
          fontWeight: bold ? boldWeight : base.fontWeight,
          fontStyle: italic ? FontStyle.italic : base.fontStyle,
        ),
      ),
    );
    index = end;
  }
  return TextSpan(style: base, children: spans);
}
