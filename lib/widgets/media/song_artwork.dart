import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SongArtwork extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const SongArtwork({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final value = source?.trim();

    if (value == null || value.isEmpty) {
      return _fallback();
    }

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return _fallback();
        },
      );
    }

    if (value.startsWith('assets/')) {
      return Image.asset(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return _fallback();
        },
      );
    }

    final String filePath = value.startsWith('file://')
        ? Uri.parse(value).toFilePath()
        : value;

    return Image.file(
      File(filePath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return fallback ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFF2C2C2E),
          alignment: Alignment.center,
          child: const Icon(
            CupertinoIcons.music_note_2,
            color: Colors.white38,
          ),
        );
  }
}
