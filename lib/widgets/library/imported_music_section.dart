import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v2/models/song.dart';
import 'package:v2/providers/library/imported_music_provider.dart';
import 'package:v2/providers/player/player_provider.dart';

class ImportedMusicSection
    extends ConsumerWidget {
  const ImportedMusicSection({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final ImportedMusicState importState =
    ref.watch(
      importedMusicProvider,
    );

    final ImportedMusicNotifier importer =
    ref.read(
      importedMusicProvider.notifier,
    );

    final List<Song> songs =
        importState.songs;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        // =====================================================
        // HEADER
        // =====================================================

        Row(
          children: [
            const Expanded(
              child: Text(
                'Imported Music',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),

            TextButton.icon(
              onPressed:
              importState.isLoading
                  ? null
                  : () async {
                final int count =
                await importer
                    .importMusic();

                if (!context.mounted) {
                  return;
                }

                if (count > 0) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        count == 1
                            ? '1 song imported'
                            : '$count songs imported',
                      ),
                    ),
                  );
                }
              },
              icon: importState.isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                CupertinoIcons
                    .square_arrow_down,
              ),
              label: Text(
                importState.isLoading
                    ? 'Loading'
                    : 'Import',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        // =====================================================
        // ERROR
        // =====================================================

        if (importState.errorMessage != null)
          Padding(
            padding:
            const EdgeInsets.only(
              bottom: 10,
            ),
            child: Text(
              importState.errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ),

        // =====================================================
        // EMPTY STATE
        // =====================================================

        if (!importState.isLoading &&
            songs.isEmpty)
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(
              22,
            ),
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                22,
              ),
              gradient:
              LinearGradient(
                begin:
                Alignment.topLeft,
                end:
                Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(
                    alpha: 0.10,
                  ),
                  Colors.white.withValues(
                    alpha: 0.04,
                  ),
                ],
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  CupertinoIcons
                      .music_note_list,
                  size: 34,
                ),

                SizedBox(
                  height: 10,
                ),

                Text(
                  'No Imported Music',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Tap Import to choose MP3 files from your device.',
                  textAlign:
                  TextAlign.center,
                ),
              ],
            ),
          ),

        // =====================================================
        // SONG LIST
        // =====================================================

        if (songs.isNotEmpty)
          ...List.generate(
            songs.length,
                (index) {
              final Song song =
              songs[index];

              return ListTile(
                contentPadding:
                EdgeInsets.zero,

                leading: Container(
                  width: 48,
                  height: 48,
                  decoration:
                  BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    gradient:
                    const LinearGradient(
                      begin:
                      Alignment.topLeft,
                      end:
                      Alignment.bottomRight,
                      colors: [
                        Color(
                          0xFF5E5CE6,
                        ),
                        Color(
                          0xFFAF52DE,
                        ),
                      ],
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons
                        .music_note_2,
                    color: Colors.white,
                  ),
                ),

                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                ),

                subtitle: const Text(
                  'Imported Music',
                ),

                trailing: PopupMenuButton<String>(
                  onSelected:
                      (value) async {
                    if (value == 'play') {
                      await ref
                          .read(
                        playerProvider
                            .notifier,
                      )
                          .playQueue(
                        songs,
                        startIndex:
                        index,
                      );
                    }

                    if (value == 'remove') {
                      await importer
                          .removeSong(
                        song,
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'play',
                      child: Text(
                        'Play',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(
                        'Remove from Library',
                      ),
                    ),
                  ],
                ),

                onTap: () async {
                  await ref
                      .read(
                    playerProvider
                        .notifier,
                  )
                      .playQueue(
                    songs,
                    startIndex:
                    index,
                  );
                },
              );
            },
          ),

        const SizedBox(
          height: 24,
        ),
      ],
    );
  }
}