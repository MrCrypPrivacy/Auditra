import 'package:flutter/material.dart';

import '../../../core/storage/notes_local_store.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/fill.dart';

class TradesScreen extends StatefulWidget {
  final String address;
  final List<Fill> fills;

  const TradesScreen({super.key, required this.address, required this.fills});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  late final NotesLocalStore _notesStore = NotesLocalStore(widget.address);
  Map<String, String> _notes = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _notesStore.loadAll();
    if (mounted) setState(() => _notes = notes);
  }

  Future<void> _editNote(BuildContext context, Fill fill) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = AppThemeScope.themeOf(context);
    final controller = TextEditingController(text: _notes[fill.tid] ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.surface,
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(color: theme.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.noteHint,
              hintStyle: TextStyle(color: theme.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _notesStore.setNote(fill.tid, controller.text);
                await _loadNotes();
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.saveNoteButton, style: TextStyle(color: theme.accent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...widget.fills]..sort((a, b) => b.time.compareTo(a.time));
    final filtered = _searchQuery.isEmpty
        ? sorted
        : sorted.where((f) => f.coin.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tradesTitle, style: AppTypography.display.copyWith(color: theme.textPrimary)),
          const SizedBox(height: 16),
          TextField(
            style: AppTypography.body.copyWith(color: theme.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              hintStyle: TextStyle(color: theme.textSecondary),
              prefixIcon: Icon(Icons.search, size: 18, color: theme.textSecondary),
              filled: true,
              fillColor: theme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.border),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(color: theme.border, height: 1),
              itemBuilder: (context, index) {
                final fill = filtered[index];
                final pnlColor = fill.closedPnl > 0
                    ? theme.positive
                    : (fill.closedPnl < 0 ? theme.negative : theme.textSecondary);
                final hasNote = _notes.containsKey(fill.tid);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${fill.coin} · ${fill.direction}',
                    style: AppTypography.body.copyWith(color: theme.textPrimary),
                  ),
                  subtitle: Text(
                    fill.time.toLocal().toString(),
                    style: AppTypography.caption.copyWith(color: theme.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fill.closedPnl.toStringAsFixed(2),
                        style: AppTypography.body.copyWith(color: pnlColor),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          hasNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
                          size: 18,
                          color: hasNote ? theme.accent : theme.textSecondary,
                        ),
                        onPressed: () => _editNote(context, fill),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
