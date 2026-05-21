import 'package:mindall_offline/ui/app_route.dart';
import 'package:drift/drift.dart' show Value, BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/app_database.dart';
import '../../domain/models/mood_entry_draft.dart';
import '../../domain/services/subscription_service.dart';
import '../widgets/bottom_button.dart';
import '../widgets/step_indicator.dart';
import '../widgets/tag_section.dart';
import '../../data/local/tables/context_tags.dart';
import 'mood_note_screen.dart';

class MoodContextScreen extends StatefulWidget {
  final MoodEntryDraft draft;
  final String moodName;
  final Color moodColor;

  const MoodContextScreen({
    super.key,
    required this.draft,
    required this.moodName,
    required this.moodColor,
  });

  @override
  State<MoodContextScreen> createState() => _MoodContextScreenState();
}

class _MoodContextScreenState extends State<MoodContextScreen> {
  late MoodEntryDraft _draft;
  late final AppDatabase _db;
  bool _editingTags = false;
  late Future<List<ContextTag>> _placeTagsFuture;
  late Future<List<ContextTag>> _activityTagsFuture;
  late Future<List<ContextTag>> _socialTagsFuture;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    _draft = widget.draft;
    _placeTagsFuture = _loadTags(ContextTagType.place);
    _activityTagsFuture = _loadTags(ContextTagType.activity);
    _socialTagsFuture = _loadTags(ContextTagType.social);
  }

  Future<List<ContextTag>> _loadTags(ContextTagType type) {
    return (_db.select(
      _db.contextTags,
    )..where((t) => t.type.equals(type.name) & t.isActive.equals(true))).get();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<SubscriptionService>().isPremium;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              _editingTags ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _editingTags = !_editingTags),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepIndicator(
                      currentStep: 0,
                      totalSteps: isPremium ? 4 : 2,
                    ),
                    const SizedBox(height: 32),

                    // ─────── title ───────
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Что ты делал(а), когда\nпочувствовал(а)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'DotGothic',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.moodName,
                            style: TextStyle(
                              color: widget.moodColor,
                              fontSize: 22,
                              fontFamily: 'DotGothic',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─────── content ───────
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ───── МЕСТО ─────
                            FutureBuilder<List<ContextTag>>(
                              future: _placeTagsFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                return TagSection(
                                  title: 'Место',
                                  tags: snapshot.data!,
                                  selectedIds: _draft.placeTagIds,
                                  editMode: _editingTags,
                                  moodColor: widget.moodColor,
                                  onDelete: (tagId) =>
                                      _deleteTag(tagId, ContextTagType.place),
                                  onToggle: (tagId) {
                                    setState(() {
                                      final updated = [..._draft.placeTagIds];
                                      updated.contains(tagId)
                                          ? updated.remove(tagId)
                                          : updated.add(tagId);
                                      _draft = _draft.copyWith(
                                        placeTagIds: updated,
                                      );
                                    });
                                  },
                                  onAdd: () async {
                                    final name = await _showAddTagDialog();
                                    if (name == null) return;
                                    final id = await _addCustomTag(
                                      ContextTagType.place,
                                      name,
                                    );
                                    if (id == null) return;
                                    setState(() {
                                      _draft = _draft.copyWith(
                                        placeTagIds: [
                                          ..._draft.placeTagIds,
                                          id,
                                        ],
                                      );
                                      _placeTagsFuture = _loadTags(
                                        ContextTagType.place,
                                      );
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // ───── ДЕЙСТВИЕ ─────
                            FutureBuilder<List<ContextTag>>(
                              future: _activityTagsFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                return TagSection(
                                  title: 'Действие',
                                  tags: snapshot.data!,
                                  selectedIds: _draft.activityTagIds,
                                  editMode: _editingTags,
                                  moodColor: widget.moodColor,
                                  onDelete: (tagId) => _deleteTag(
                                    tagId,
                                    ContextTagType.activity,
                                  ),
                                  onToggle: (tagId) {
                                    setState(() {
                                      final updated = [
                                        ..._draft.activityTagIds,
                                      ];
                                      updated.contains(tagId)
                                          ? updated.remove(tagId)
                                          : updated.add(tagId);
                                      _draft = _draft.copyWith(
                                        activityTagIds: updated,
                                      );
                                    });
                                  },
                                  onAdd: () async {
                                    final name = await _showAddTagDialog();
                                    if (name == null) return;
                                    final id = await _addCustomTag(
                                      ContextTagType.activity,
                                      name,
                                    );
                                    if (id == null) return;
                                    setState(() {
                                      _draft = _draft.copyWith(
                                        activityTagIds: [
                                          ..._draft.activityTagIds,
                                          id,
                                        ],
                                      );
                                      _activityTagsFuture = _loadTags(
                                        ContextTagType.activity,
                                      );
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // ───── ОБЩЕСТВО ─────
                            FutureBuilder<List<ContextTag>>(
                              future: _socialTagsFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                return TagSection(
                                  title: 'Общество',
                                  tags: snapshot.data!,
                                  selectedIds: _draft.socialTagIds,
                                  editMode: _editingTags,
                                  moodColor: widget.moodColor,
                                  onDelete: (tagId) =>
                                      _deleteTag(tagId, ContextTagType.social),
                                  onToggle: (tagId) {
                                    setState(() {
                                      final updated = [..._draft.socialTagIds];
                                      updated.contains(tagId)
                                          ? updated.remove(tagId)
                                          : updated.add(tagId);
                                      _draft = _draft.copyWith(
                                        socialTagIds: updated,
                                      );
                                    });
                                  },
                                  onAdd: () async {
                                    final name = await _showAddTagDialog();
                                    if (name == null) return;
                                    final id = await _addCustomTag(
                                      ContextTagType.social,
                                      name,
                                    );
                                    if (id == null) return;
                                    setState(() {
                                      _draft = _draft.copyWith(
                                        socialTagIds: [
                                          ..._draft.socialTagIds,
                                          id,
                                        ],
                                      );
                                      _socialTagsFuture = _loadTags(
                                        ContextTagType.social,
                                      );
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Кнопка теперь всегда с одинаковым отступом
          BottomButton(
            text: 'Далее',
            color: widget.moodColor,
            onTap: _goToMoodNote,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTag(int tagId, ContextTagType type) async {
    await (_db.update(_db.contextTags)..where((t) => t.id.equals(tagId))).write(
      const ContextTagsCompanion(isActive: Value(false)),
    );

    if (!mounted) return;
    setState(() {
      if (type == ContextTagType.place) {
        _draft = _draft.copyWith(
          placeTagIds: [..._draft.placeTagIds]..remove(tagId),
        );
        _placeTagsFuture = _loadTags(ContextTagType.place);
      } else if (type == ContextTagType.activity) {
        _draft = _draft.copyWith(
          activityTagIds: [..._draft.activityTagIds]..remove(tagId),
        );
        _activityTagsFuture = _loadTags(ContextTagType.activity);
      } else if (type == ContextTagType.social) {
        _draft = _draft.copyWith(
          socialTagIds: [..._draft.socialTagIds]..remove(tagId),
        );
        _socialTagsFuture = _loadTags(ContextTagType.social);
      }
    });
  }

  void _goToMoodNote() {
    Navigator.push(
      context,
      AppRoute(
        page: MoodNoteScreen(
          draft: _draft,
          moodName: widget.moodName,
          moodColor: widget.moodColor,
        ),
      ),
    );
  }

  Future<String?> _showAddTagDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: const RoundedRectangleBorder(),
          content: TextField(
            textAlign: TextAlign.center,
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'DotGothic',
              color: Colors.white,
            ),
            cursorColor: widget.moodColor,
            decoration: InputDecoration(
              hintText: 'добавить тег',
              hintStyle: TextStyle(color: widget.moodColor.withOpacity(0.8)),
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.moodColor, width: 2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.moodColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.pop(context, text.isEmpty ? null : text);
              },
              child: const Text('Ок', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _addCustomTag(ContextTagType type, String name) async {
    return _db
        .into(_db.contextTags)
        .insert(
          ContextTagsCompanion.insert(
            name: name,
            type: type,
            isCustom: const Value(true),
          ),
        );
  }
}
