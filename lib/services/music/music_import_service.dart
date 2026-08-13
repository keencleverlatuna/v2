import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:v2/models/song.dart';

class MusicImportService {
  const MusicImportService();

  // =========================================================
  // PICK + IMPORT SONGS
  // =========================================================

  Future<List<Song>> pickAndImportSongs() async {
    final FilePickerResult? result =
    await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'mp3',
      ],
    );

    if (result == null || result.files.isEmpty) {
      debugPrint('Music import cancelled.');
      return const <Song>[];
    }

    final Directory appDirectory =
    await getApplicationDocumentsDirectory();

    final Directory musicDirectory =
    Directory(
      '${appDirectory.path}'
          '${Platform.pathSeparator}'
          'melody_music',
    );

    final Directory artworkDirectory =
    Directory(
      '${appDirectory.path}'
          '${Platform.pathSeparator}'
          'melody_artwork',
    );

    if (!await musicDirectory.exists()) {
      await musicDirectory.create(
        recursive: true,
      );
    }

    if (!await artworkDirectory.exists()) {
      await artworkDirectory.create(
        recursive: true,
      );
    }

    final List<Song> importedSongs =
    <Song>[];

    for (
    int index = 0;
    index < result.files.length;
    index++
    ) {
      final PlatformFile pickedFile =
      result.files[index];

      try {
        final String? pickedPath =
            pickedFile.path;

        if (pickedPath == null ||
            pickedPath.trim().isEmpty) {
          debugPrint(
            'Import skipped: ${pickedFile.name} has no readable path.',
          );
          continue;
        }

        final File sourceFile =
        File(pickedPath);

        if (!await sourceFile.exists()) {
          debugPrint(
            'Import skipped: source file does not exist.',
          );
          continue;
        }

        final int sourceSize =
        await sourceFile.length();

        if (sourceSize <= 0) {
          debugPrint(
            'Import skipped: ${pickedFile.name} is empty.',
          );
          continue;
        }

        final String originalName =
            pickedFile.name;

        final String fallbackTitle =
        _titleFromFileName(
          originalName,
        );

        final String safeFileName =
        _safeFileName(
          originalName,
        );

        final String uniqueId =
        DateTime.now()
            .microsecondsSinceEpoch
            .toString();

        final File destinationFile =
        File(
          '${musicDirectory.path}'
              '${Platform.pathSeparator}'
              '${uniqueId}_$index'
              '_$safeFileName',
        );

        await sourceFile.copy(
          destinationFile.path,
        );

        if (!await destinationFile.exists()) {
          debugPrint(
            'Import failed: destination file was not created.',
          );
          continue;
        }

        final int copiedSize =
        await destinationFile.length();

        if (copiedSize <= 0 ||
            copiedSize != sourceSize) {
          if (await destinationFile.exists()) {
            await destinationFile.delete();
          }

          debugPrint(
            'Import failed: copied audio file is invalid.',
          );
          continue;
        }

        String title = fallbackTitle;
        String artist = 'Unknown Artist';
        String? lyrics;
        String? artworkPath;

        // =====================================================
        // READ EMBEDDED MP3 METADATA
        // =====================================================

        try {
          final AudioMetadata metadata =
          readMetadata(
            destinationFile,
            getImage: true,
          );

          final String? metadataTitle =
          _usableText(
            metadata.title,
          );

          final String? metadataArtist =
          _usableText(
            metadata.artist,
          );

          final String? metadataLyrics =
          _usableText(
            metadata.lyrics,
          );

          if (metadataTitle != null) {
            title = metadataTitle;
          }

          if (metadataArtist != null) {
            artist = metadataArtist;
          }

          if (metadataLyrics != null) {
            lyrics = metadataLyrics;
          }

          // ===================================================
          // EXTRACT EMBEDDED COVER ART
          // ===================================================

          for (final picture in metadata.pictures) {
            if (picture.bytes.isEmpty) {
              continue;
            }

            final String extension =
            _imageExtension(
              picture.mimetype,
            );

            final File artworkFile =
            File(
              '${artworkDirectory.path}'
                  '${Platform.pathSeparator}'
                  '${uniqueId}_$index.$extension',
            );

            await artworkFile.writeAsBytes(
              picture.bytes,
              flush: true,
            );

            if (await artworkFile.exists() &&
                await artworkFile.length() > 0) {
              artworkPath =
                  artworkFile.path;
            }

            break;
          }

          debugPrint(
            'Metadata title: ${metadata.title}',
          );

          debugPrint(
            'Metadata artist: ${metadata.artist}',
          );

          debugPrint(
            'Metadata album: ${metadata.album}',
          );

          debugPrint(
            'Metadata artwork count: ${metadata.pictures.length}',
          );
        } catch (error, stackTrace) {
          // Metadata is optional. The song should still import.
          debugPrint(
            'Metadata read failed for ${pickedFile.name}: $error',
          );

          debugPrint(
            'Metadata stack trace: $stackTrace',
          );
        }

        final Song song =
        Song(
          id:
          'imported-$uniqueId-$index',
          title: title,
          artist: artist,
          audioUrl:
          destinationFile.path,
          artworkUrl:
          artworkPath,
          lyrics: lyrics,
        );

        importedSongs.add(
          song,
        );

        debugPrint(
          '========================================',
        );

        debugPrint(
          'Imported song: ${song.title}',
        );

        debugPrint(
          'Artist: ${song.artist}',
        );

        debugPrint(
          'Artwork: ${song.artworkUrl ?? 'none'}',
        );

        debugPrint(
          'Imported path: ${song.audioUrl}',
        );

        debugPrint(
          'Imported size: $copiedSize bytes',
        );

        debugPrint(
          '========================================',
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Import failed for ${pickedFile.name}: $error',
        );

        debugPrint(
          'Import stack trace: $stackTrace',
        );
      }
    }

    return importedSongs;
  }

  // =========================================================
  // METADATA TEXT
  // =========================================================

  String? _usableText(
      String? value,
      ) {
    final String? cleaned =
    value?.trim();

    if (cleaned == null ||
        cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }

  // =========================================================
  // ARTWORK EXTENSION
  // =========================================================

  String _imageExtension(
      String mimeType,
      ) {
    final String normalized =
    mimeType
        .trim()
        .toLowerCase();

    if (normalized.contains('png')) {
      return 'png';
    }

    if (normalized.contains('webp')) {
      return 'webp';
    }

    if (normalized.contains('gif')) {
      return 'gif';
    }

    return 'jpg';
  }

  // =========================================================
  // TITLE FROM FILE NAME
  // =========================================================

  String _titleFromFileName(
      String fileName,
      ) {
    String value =
    fileName.trim();

    final int extensionIndex =
    value.lastIndexOf('.');

    if (extensionIndex > 0) {
      value = value.substring(
        0,
        extensionIndex,
      );
    }

    value = value
        .replaceAll('_', ' ')
        .trim();

    while (value.contains('  ')) {
      value = value.replaceAll(
        '  ',
        ' ',
      );
    }

    if (value.isEmpty) {
      return 'Imported Song';
    }

    return value;
  }

  // =========================================================
  // SAFE FILE NAME
  // =========================================================

  String _safeFileName(
      String fileName,
      ) {
    final String cleaned =
    fileName.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9._-]',
      ),
      '_',
    );

    if (cleaned.isEmpty) {
      return 'song.mp3';
    }

    if (!cleaned
        .toLowerCase()
        .endsWith('.mp3')) {
      return '$cleaned.mp3';
    }

    return cleaned;
  }
}
