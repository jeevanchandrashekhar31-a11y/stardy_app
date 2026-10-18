import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'error_type.dart';

/// Brand kit colors (Social Media Brand Kit, "Color usage").
class _ErrorColors {
  _ErrorColors._();

  static const red = Color(0xFF99131D);
  static const black = Color(0xFF000000);
  static const grey = Color(0xFFD9D9D9);
  static const white = Color(0xFFFFFFFF);
}

/// Full-screen error page for all eight Stardy error states.
///
/// ```dart
/// StardyErrorPage(
///   type: StardyErrorType.notFound,
///   onPrimary: () => context.go('/'),
///   onSecondary: () => context.pop(),
/// )
/// ```
///
/// For [StardyErrorType.rateLimited] the primary button stays disabled and
/// counts down from [retryAfterSeconds] before [onPrimary] can be used.
class StardyErrorPage extends StatefulWidget {
  const StardyErrorPage({
    super.key,
    required this.type,
    required this.onPrimary,
    this.onSecondary,
    this.retryAfterSeconds = 30,
  });

  final StardyErrorType type;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final int retryAfterSeconds;

  @override
  State<StardyErrorPage> createState() => _StardyErrorPageState();
}

class _StardyErrorPageState extends State<StardyErrorPage> {
  Timer? _timer;
  late int _remaining;

  bool get _locked =>
      widget.type == StardyErrorType.rateLimited && _remaining > 0;

  @override
  void initState() {
    super.initState();
    _remaining =
        widget.type == StardyErrorType.rateLimited ? widget.retryAfterSeconds : 0;
    if (_remaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _remaining--);
        if (_remaining <= 0) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = StardyErrorContent.all[widget.type]!;
    final primaryLabel = _locked
        ? '${content.primaryLabel} in ${_remaining}s'
        : content.primaryLabel;

    return Scaffold(
      backgroundColor: _ErrorColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(code: content.code),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Hero(content: content),
                    const SizedBox(height: 32),
                    _Headline(text: content.headline),
                    const SizedBox(height: 20),
                    Text(
                      content.body,
                      style: GoogleFonts.robotoMono(
                        fontSize: 15,
                        height: 1.6,
                        color: _ErrorColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _ErrorColors.black)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                children: [
                  _ErrorButton(
                    label: primaryLabel,
                    style: _locked
                        ? _ButtonStyle.disabled
                        : _ButtonStyle.primary,
                    onTap: _locked ? null : widget.onPrimary,
                  ),
                  if (content.secondaryLabel != null &&
                      widget.onSecondary != null) ...[
                    const SizedBox(height: 10),
                    _ErrorButton(
                      label: content.secondaryLabel!,
                      style: _ButtonStyle.outline,
                      onTap: widget.onSecondary,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _SmallCaps(content.footerLabel)),
                  const SizedBox(width: 12),
                  const _SmallCaps('WWW.STARDYAI.COM'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallCaps extends StatelessWidget {
  const _SmallCaps(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.mukta(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: _ErrorColors.black,
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.code});

  final String? code;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _ErrorColors.black)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SmallCaps('STARDY AI'),
            const SizedBox(width: 12),
            _SmallCaps(code != null ? 'ERR $code' : 'ERROR'),
          ],
        ),
      );
}

/// Fixed 104px block: the error code for HTTP errors, an icon tile otherwise.
class _Hero extends StatelessWidget {
  const _Hero({required this.content});

  final StardyErrorContent content;

  @override
  Widget build(BuildContext context) {
    const size = 104.0;
    if (content.code != null) {
      return Container(
        height: size,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: _ErrorColors.red,
        alignment: Alignment.center,
        child: Text(
          content.code!,
          style: GoogleFonts.mukta(
            fontSize: 80,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -3.2,
            color: _ErrorColors.white,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      color: _ErrorColors.red,
      alignment: Alignment.center,
      child: Icon(content.icon, size: 52, color: _ErrorColors.white),
    );
  }
}

/// Mukta ExtraBold, all caps, with `*emphasised*` words on solid red blocks.
class _Headline extends StatelessWidget {
  const _Headline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.mukta(
      fontSize: 40,
      height: 1.3,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.6,
      color: _ErrorColors.black,
    );

    final spans = <InlineSpan>[];
    final parts = text.split('*');
    for (var i = 0; i < parts.length; i++) {
      final highlighted = i.isOdd;
      final words = parts[i].split(' ').where((w) => w.isNotEmpty).toList();
      for (var w = 0; w < words.length; w++) {
        final word = words[w];
        if (highlighted) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              color: _ErrorColors.red,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                word,
                style: base.copyWith(color: _ErrorColors.white),
              ),
            ),
          ));
        } else {
          spans.add(TextSpan(text: word));
        }
        final lastWordOfSegment = w == words.length - 1;
        final lastSegment = i == parts.length - 1;
        if (!(lastWordOfSegment && lastSegment)) {
          spans.add(const TextSpan(text: ' '));
        }
      }
    }

    return Semantics(
      header: true,
      label: text.replaceAll('*', ''),
      child: ExcludeSemantics(
        child: Text.rich(TextSpan(style: base, children: spans)),
      ),
    );
  }
}

enum _ButtonStyle { primary, outline, disabled }

class _ErrorButton extends StatelessWidget {
  const _ErrorButton({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final _ButtonStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPrimary = style == _ButtonStyle.primary;
    final background = switch (style) {
      _ButtonStyle.primary => _ErrorColors.red,
      _ButtonStyle.disabled => _ErrorColors.grey,
      _ButtonStyle.outline => _ErrorColors.white,
    };
    final border = isPrimary ? _ErrorColors.red : _ErrorColors.black;
    final foreground = isPrimary ? _ErrorColors.white : _ErrorColors.black;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ExcludeSemantics(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.64,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
