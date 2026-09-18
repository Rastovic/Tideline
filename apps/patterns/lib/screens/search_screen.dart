import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import 'day_detail_screen.dart';
import '../l10n/app_language.dart';

/// Finding an entry by what it says: the diary and photo captions.
///
/// **Words, not markers.** Numbers are read in reports; this is for "the week
/// I wrote about the conflict at work", which no chart can find. Every hit
/// opens its day, because the entry means most next to what else was logged.
class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.controller, super.key});

  final PatternsController controller;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  bool _includePrivate = false;
  List<SearchHit>? _hits;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _run);
  }

  Future<void> _run() async {
    final query = _query.text;
    final hits = await widget.controller
        .search(query, includePrivate: _includePrivate);
    // A slow search for an old query must not overwrite a newer one.
    if (!mounted || query != _query.text) return;
    setState(() => _hits = query.trim().isEmpty ? null : hits);
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final hits = _hits;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: (_) => _run(),
          textInputAction: TextInputAction.search,
          style: theme.typography.body,
          decoration: InputDecoration(
            hintText: context.s.searchHint,
            border: InputBorder.none,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.sm,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includePrivate,
              onChanged: (on) {
                setState(() => _includePrivate = on);
                _run();
              },
              title: Text(context.s.includePrivate, style: theme.typography.body),
            ),
            const SizedBox(height: VitalsSpacing.md),
            if (hits != null && hits.isEmpty)
              Text(
                context.s.nothingFound,
                style: theme.typography.body.copyWith(color: colors.inkMuted),
              ),
            for (final hit in hits ?? const <SearchHit>[])
              Padding(
                padding: const EdgeInsets.only(bottom: VitalsSpacing.sm),
                child: InkWell(
                  borderRadius: VitalsRadius.nestedAll,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DayDetailScreen(
                        controller: widget.controller,
                        dayKey: hit.dayKey,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(VitalsSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: VitalsRadius.nestedAll,
                      border: Border.all(color: colors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            _dayLabel(hit.dayKey),
                            hit.markerName ?? context.s.photoLower,
                            if (hit.isNote) context.s.note.toLowerCase(),
                            if (hit.isPrivate) context.s.privateLower,
                          ].join(' · '),
                          style: theme.typography.caption
                              .copyWith(color: colors.inkMuted),
                        ),
                        const SizedBox(height: VitalsSpacing.xs),
                        Text(
                          hit.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// `2026-08-19` as `19.8.2026.`. The year stays: search reaches across all of
  /// them, and "19.8." alone is two different summers.
  static String _dayLabel(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return dayKey;
    return '${int.tryParse(parts[2]) ?? parts[2]}.'
        '${int.tryParse(parts[1]) ?? parts[1]}.${parts[0]}.';
  }
}
