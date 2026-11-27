import '../../../health_coach/domain/coach_history_summary.dart';
import '../../../meal_log/domain/catalog_meal_draft.dart';
import '../../domain/coach_daily_checkin.dart';
import '../../../health_coach/data/coach_health_store.dart';
import '../../../health_coach/domain/health_coach_orchestrator.dart';
import '../../../health_coach/domain/health_coach_profile.dart';
import '../../../health_coach/domain/coach_trusted_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/conversation_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../data/coach_store.dart';
import '../../domain/coach_engine.dart';

/// One rendered chat entry: either a persisted message or an in-flight one
/// with a stable local id.
class CoachEntry {
  const CoachEntry({
    required this.id,
    required this.isUser,
    required this.text,
    this.stats = const [],
    this.advice,
    this.persisted = false,
    this.failed = false,
    this.origin = 'rules',
    this.sourceIds = const [],
    this.localRecordSummary = false,
  });

  final String id;
  final bool isUser;
  final String text;
  final List<CoachStat> stats;
  final String? advice;
  final bool persisted;
  final bool failed;
  final String origin;
  final List<String> sourceIds;
  final bool localRecordSummary;

  CoachEntry copyWith({bool? persisted, bool? failed}) => CoachEntry(
    id: id,
    isUser: isUser,
    text: text,
    stats: stats,
    advice: advice,
    persisted: persisted ?? this.persisted,
    failed: failed ?? this.failed,
    origin: origin,
    sourceIds: sourceIds,
    localRecordSummary: localRecordSummary,
  );
}

@immutable
class CoachState {
  const CoachState({
    required this.status,
    this.entries = const [],
    this.thinking = false,
    this.hasRecords = false,
    this.sendFailure = false,
  });

  final CoachStatus status;
  final List<CoachEntry> entries;

  /// True while a rule-based answer is being computed and stored.
  final bool thinking;

  /// Whether the user has any meal records at all (drives the header note).
  final bool hasRecords;

  /// Set briefly when persisting a message failed; the UI offers retry.
  final bool sendFailure;

  CoachState copyWith({
    CoachStatus? status,
    List<CoachEntry>? entries,
    bool? thinking,
    bool? hasRecords,
    bool? sendFailure,
  }) => CoachState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    thinking: thinking ?? this.thinking,
    hasRecords: hasRecords ?? this.hasRecords,
    sendFailure: sendFailure ?? this.sendFailure,
  );
}

enum CoachStatus { loading, ready, error }

/// Deterministic tools plus an optional, explicitly consented question provider.
class CoachCubit extends Cubit<CoachState> {
  CoachCubit({
    required this.userId,
    this.currentUid,
    this.healthStore,
    required this.store,
    required this.nutrition,
    required this.locale,
    this.engine = const RuleBasedCoach(),
    this.waterTargetMl,
    this.loadWaterTarget,
    this.healthOrchestrator,
    this.contextSharingAvailable = false,
    this.healthConsent = const HealthCoachConsent(),
    this.healthProfile = const HealthCoachProfile(),
    DateTime Function()? clock,
    int Function()? idSeed,
  }) : _clock = clock ?? DateTime.now,
       _idSeed = idSeed ?? _defaultSeed,
       super(const CoachState(status: CoachStatus.loading));

  final bool contextSharingAvailable;
  final String userId;
  final String? Function()? currentUid;
  bool get inactive =>
      isClosed ||
      userId.isEmpty ||
      (currentUid != null && currentUid!() != userId);
  void assertActive() {
    if (inactive) throw StateError('Account no longer active');
  }

  @override
  void emit(CoachState state) {
    if (!inactive) super.emit(state);
  }

  @override
  Future<void> close() {
    _generation++;
    healthOrchestrator?.cancelPending();
    _flaggedReplies.clear();
    _chosenHabits.clear();
    _habitCompletions.clear();
    _dailyCheckins.clear();
    return super.close();
  }

  final CoachHealthStore? healthStore;
  SavedCoachChoices savedHealth = const SavedCoachChoices();
  bool healthLoadFailed = false;
  Future<void> loadSavedHealth() async {
    final store = healthStore;
    if (store == null) return;
    try {
      final saved = await store.load();
      assertActive();
      savedHealth = saved;
      healthProfile = HealthCoachProfile.fromSaved(
        saved.profile,
        goals: saved.goals,
      );
      _chosenHabits
        ..clear()
        ..addAll(saved.habits.where(supportedHabits.contains));
      _habitCompletions
        ..clear()
        ..addAll(
          (saved.fields.contains('habits')
                  ? saved.checkins
                  : <String, List<String>>{})
              .map((k, v) => MapEntry(k, v.toSet())),
        );
      healthLoadFailed = false;
      emit(state.copyWith());
    } catch (_) {
      healthLoadFailed = true;
      emit(state.copyWith());
    }
  }

  Future<void> saveHealthFields(Set<String> fields) async {
    assertActive();
    final store = healthStore;
    if (store == null) throw StateError('Storage unavailable');
    if (healthLoadFailed) throw StateError('Reload saved data first');
    final day = habitTodayKey;
    final map = healthProfile.toContext()..remove('goals');
    final value = SavedCoachChoices(
      profile: Map.fromEntries(
        map.entries.where((e) => fields.contains(e.key)),
      ),
      fields: fields.toList()..sort(),
      goals: fields.contains('goals') ? healthProfile.goals : [],
      habits: fields.contains('habits') ? chosenHabits.toList() : [],
      checkins: fields.contains('habits')
          ? {day: (_habitCompletions[day] ?? {}).toList()}
          : {},
    );
    await store.save(value, day);
    assertActive();
    savedHealth = await store.load();
    assertActive();
    emit(state.copyWith());
  }

  Future<void> deleteHealthDay(String day) async {
    assertActive();
    await healthStore!.deleteDay(day);
    assertActive();
    _habitCompletions.remove(day);
    savedHealth = await healthStore!.load();
    assertActive();
    emit(state.copyWith());
  }

  Future<void> deleteSavedHealth() async {
    assertActive();
    await healthStore!.deleteAll();
    assertActive();
    savedHealth = const SavedCoachChoices();
    emit(state.copyWith());
  }

  final CoachStore store;
  final NutritionRepository nutrition;
  final String locale;
  final RuleBasedCoach engine;

  /// The user's configured water goal when one exists upstream; null keeps
  /// water answers honest about the missing goal.
  final double? waterTargetMl;
  final Future<double?> Function()? loadWaterTarget;
  final HealthCoachOrchestrator? healthOrchestrator;
  HealthCoachConsent healthConsent;
  HealthCoachProfile healthProfile;

  bool get externalQuestionEnabled =>
      healthOrchestrator != null && healthConsent.externalAi;

  /// Session-only choices. Updating them also refreshes visible capability state.
  void updateHealthChoices(
    HealthCoachConsent consent,
    HealthCoachProfile profile,
  ) {
    assertActive();
    // A privacy change must never wait for an external reply. Invalidate the
    // request before cancelling transport so late completions cannot persist.
    if (state.thinking) {
      _generation++;
      healthOrchestrator?.cancelPending();
      _pending = null;
      emit(state.copyWith(thinking: false, sendFailure: false));
    }
    healthConsent = consent;
    healthProfile = profile;
    emit(state.copyWith());
  }

  final Map<String, String> _flaggedReplies = {};
  bool replyFlagged(String id) => !inactive && _flaggedReplies.containsKey(id);
  void flagReply(String id, String reason) {
    assertActive();
    if (!const {'unsafe', 'incorrect', 'other'}.contains(reason)) {
      throw ArgumentError.value(reason);
    }
    if (!state.entries.any((e) => e.id == id && !e.isUser)) {
      throw StateError('Unknown coach reply');
    }
    _flaggedReplies[id] = reason;
    emit(state.copyWith());
  }

  void restoreReply(String id) {
    assertActive();
    _flaggedReplies.remove(id);
    emit(state.copyWith());
  }

  final _dailyCheckins = <String, CoachDailyCheckin>{};
  CoachDailyCheckin get dailyCheckin => inactive
      ? const CoachDailyCheckin()
      : _dailyCheckins[habitTodayKey] ?? const CoachDailyCheckin();
  void updateDailyCheckin(CoachDailyCheckin value) {
    assertActive();
    value.validate();
    if (value.empty) {
      _dailyCheckins.remove(habitTodayKey);
    } else {
      _dailyCheckins[habitTodayKey] = value;
    }
    emit(state.copyWith());
  }

  static const supportedHabits = {
    'log_meal',
    'prepare_meal',
    'review_ingredients',
  };
  final Set<String> _chosenHabits = {};
  final Map<String, Set<String>> _habitCompletions = {};
  Set<String> get chosenHabits =>
      inactive ? const {} : Set.unmodifiable(_chosenHabits);
  String get habitTodayKey => SufraDateUtils.toDateKey(_clock().toLocal());
  bool habitDone(String id) =>
      !inactive && (_habitCompletions[habitTodayKey]?.contains(id) ?? false);

  /// Explicit saved/session check-ins only, never inferred from meals.
  Map<String, Set<String>> habitHistory(int days) {
    if (inactive) return const {};
    if (days < 1 || days > 366) throw ArgumentError.value(days);
    final end = SufraDateUtils.startOfDay(_clock().toLocal());
    final start = SufraDateUtils.toDateKey(
      SufraDateUtils.shiftDays(end, 1 - days),
    );
    final last = SufraDateUtils.toDateKey(end);
    return Map.unmodifiable(
      Map.fromEntries(
        _habitCompletions.entries
            .where(
              (e) => e.key.compareTo(start) >= 0 && e.key.compareTo(last) <= 0,
            )
            .map(
              (e) => MapEntry(
                e.key,
                Set<String>.unmodifiable(
                  e.value.where(supportedHabits.contains),
                ),
              ),
            ),
      ),
    );
  }

  void chooseHabit(String id, bool selected) {
    assertActive();
    if (!supportedHabits.contains(id)) throw ArgumentError.value(id);
    if (selected) {
      _chosenHabits.add(id);
    } else {
      _chosenHabits.remove(id);
      for (final day in _habitCompletions.values) {
        day.remove(id);
      }
    }
    emit(state.copyWith());
  }

  void markHabit(String id, bool done) {
    assertActive();
    if (!_chosenHabits.contains(id)) throw StateError('Choose a habit first');
    final day = _habitCompletions.putIfAbsent(habitTodayKey, () => {});
    if (done) {
      day.add(id);
    } else {
      day.remove(id);
    }
    emit(state.copyWith());
  }

  final DateTime Function() _clock;
  final int Function() _idSeed;

  static int _defaultSeed() => DateTime.now().microsecondsSinceEpoch;

  int _generation = 0;
  int _counter = 0;
  ({
    String text,
    String? quickId,
    DateTime at,
    CoachEntry user,
    String answerId,
    CatalogMealDraft? reviewedCalculation,
    CoachHistorySummary? reviewedHistory,
  })?
  _pending;
  Future<void> retryPending() async {
    final pending = _pending;
    if (pending != null) {
      await send(
        pending.text,
        quickId: pending.quickId,
        reviewedCalculation: pending.reviewedCalculation,
        reviewedHistory: pending.reviewedHistory,
      );
    }
  }

  Future<void> load() async {
    assertActive();
    final myGeneration = ++_generation;
    emit(state.copyWith(status: CoachStatus.loading));
    try {
      if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
      final messages = await store.loadMessages(userId);
      assertActive();
      var hasRecords = false;
      try {
        hasRecords = (await nutrition.getMealEntries(userId)).isNotEmpty;
      } catch (_) {
        assertActive();
        // Chat can open without numeric records. Record-based prompts still
        // fail honestly on send; emergency help must remain reachable.
      }
      if (inactive || myGeneration != _generation) return;
      emit(
        CoachState(
          status: CoachStatus.ready,
          hasRecords: hasRecords,
          entries: [
            for (final message in messages)
              CoachEntry(
                id: message.messageId,
                isUser: message.role == 'user',
                text: message.content,
                stats: _statsFromMetadata(message.metadata),
                advice: message.metadata?['advice'] as String?,
                localRecordSummary:
                    message.metadata?['localRecordSummary'] == true,
                persisted: true,
                origin:
                    const {
                      'ai',
                      'safety',
                      'unavailable',
                    }.contains(message.metadata?['engine'])
                    ? message.metadata!['engine'] as String
                    : 'rules',
                sourceIds: message.metadata?['sourceIds'] is List
                    ? (message.metadata!['sourceIds'] as List)
                          .whereType<String>()
                          .toList()
                    : const [],
              ),
          ],
        ),
      );
    } catch (_) {
      if (inactive || myGeneration != _generation) return;
      emit(const CoachState(status: CoachStatus.error));
    }
  }

  static List<CoachStat> _statsFromMetadata(Map<String, dynamic>? metadata) {
    final raw = metadata?['stats'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          CoachStat(
            label: '${entry['label'] ?? ''}',
            value: '${entry['value'] ?? ''}',
          ),
    ];
  }

  Future<CoachData> _collectData() async {
    assertActive();
    final meals = await nutrition.getMealEntries(userId);
    assertActive();
    final logs = await nutrition.getDailyLogs(userId, limit: 10);
    double? target;
    assertActive();
    final profiles = await nutrition.getNutritionProfiles(userId);
    assertActive();
    for (final profile in profiles) {
      if (profile.isActive &&
          profile.dailyCalorieTarget.isFinite &&
          profile.dailyCalorieTarget > 0) {
        target = profile.dailyCalorieTarget;
      }
    }
    final waterTarget = loadWaterTarget == null
        ? waterTargetMl
        : await loadWaterTarget!();
    assertActive();
    return CoachData(
      todayKey: SufraDateUtils.toDateKey(_clock()),
      locale: locale,
      meals: meals
          .where((m) => m.userId == userId && m.analysisStatus == 'confirmed')
          .toList(),
      dailyLogs: logs,
      calorieTarget: target,
      waterTargetMl:
          waterTarget != null && waterTarget.isFinite && waterTarget > 0
          ? waterTarget
          : null,
      goals: healthProfile.goals,
    );
  }

  Future<CoachData> readLocalReview() async {
    final data = await _collectData();
    assertActive();
    return data;
  }

  /// Sends a user message, computes the deterministic answer and persists
  /// both. In-flight entries roll back if their store call fails.
  Future<CoachHistorySummary> previewHistory(int days) async {
    assertActive();
    final records = await nutrition.getMealEntries(userId);
    assertActive();
    return CoachHistorySummary.build(
      records,
      uid: userId,
      now: _clock(),
      days: days,
    );
  }

  Future<void> send(
    String text, {
    String? quickId,
    CatalogMealDraft? reviewedCalculation,
    CoachHistorySummary? reviewedHistory,
  }) async {
    if (inactive || text.length > 1000) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty && quickId == null) return;
    if (state.thinking) return;
    final myGeneration = _generation;
    final existingPending = _pending;
    if (existingPending != null &&
        (existingPending.text != trimmed ||
            existingPending.quickId != quickId)) {
      return;
    }
    // A failed stored request owns its exact reviewed payload until retry or
    // cancellation. Reusing generic text must not replace that payload.
    if (existingPending != null) {
      reviewedCalculation = existingPending.reviewedCalculation;
      reviewedHistory = existingPending.reviewedHistory;
    }
    final now = existingPending?.at ?? _clock();
    final userEntry =
        existingPending?.user ??
        CoachEntry(
          id: 'u_${_idSeed()}_${_counter++}',
          isUser: true,
          text: quickId == null ? trimmed : _quickLabel(quickId),
        );
    final answerId =
        existingPending?.answerId ?? 'c_${_idSeed()}_${_counter++}';
    _pending = (
      text: trimmed,
      quickId: quickId,
      at: now,
      user: userEntry,
      answerId: answerId,
      reviewedCalculation: reviewedCalculation,
      reviewedHistory: reviewedHistory,
    );
    emit(
      state.copyWith(
        entries: [
          for (final e in state.entries)
            if (e.id != userEntry.id) e,
          userEntry,
        ],
        thinking: true,
        sendFailure: false,
      ),
    );
    try {
      assertActive();
      await store.appendMessage(
        userId,
        _toMessage(userEntry, now, role: 'user'),
      );
      assertActive();
      final localSafety = quickId == null
          ? const CoachSafetyPreflight().refusal(trimmed, healthProfile, locale)
          : null;
      // Typed-only external chat does not depend on diary availability. Local
      // record cards are optional and never fabricate zero intake after errors.
      late final CoachData data;
      try {
        data = await _collectData();
      } catch (_) {
        assertActive();
        if (myGeneration != _generation) return;
        if (localSafety == null &&
            (healthOrchestrator == null ||
                !healthConsent.externalAi ||
                quickId != null)) {
          rethrow;
        }
        data = CoachData(
          todayKey: SufraDateUtils.toDateKey(_clock()),
          locale: locale,
        );
      }
      assertActive();
      if (myGeneration != _generation) return;
      CoachAnswer? answer;
      late final CoachEntry coachEntry;
      final orchestrator = healthOrchestrator;
      if (orchestrator != null && healthConsent.externalAi && quickId == null) {
        final log = data.dailyLogs
            .where((l) => l.dateKey == data.todayKey)
            .firstOrNull;
        final snapshot = CoachTrustedSnapshot.forDay(
          dateKey: data.todayKey,
          meals: data.meals,
          log: log,
        );
        final reply = await orchestrator.ask(
          question: trimmed,
          reviewedCalculation: reviewedCalculation,
          reviewedHistory: reviewedHistory,
          locale: locale,
          consent: healthConsent,
          profile: healthProfile,
          facts: snapshot.externalFactsForDate(data.todayKey),
          history: state.entries
              .where((e) => e.id != userEntry.id)
              .map((e) => e.text)
              .toList(),
        );
        assertActive();
        if (myGeneration != _generation) return;
        coachEntry = CoachEntry(
          id: answerId,
          isUser: false,
          text: reply.text,
          origin: reply.origin.name,
          sourceIds: reply.sourceIds,
          localRecordSummary:
              reply.origin == CoachReplyOrigin.ai &&
              reply.trustedToolStats.isEmpty,
          stats: [
            for (final stat in reply.trustedToolStats.entries)
              CoachStat(label: stat.key, value: stat.value),
            if (reply.origin == CoachReplyOrigin.ai)
              for (final metric in snapshot.metrics)
                if (metric.value != null)
                  CoachStat(
                    label: metric.label(locale),
                    value: '${metric.value!.toStringAsFixed(0)} ${metric.unit}',
                  ),
          ],
          advice: null,
        );
      } else {
        final stopped = localSafety;
        answer = stopped != null
            ? CoachAnswer(text: stopped)
            : quickId == null
            ? engine.answer(trimmed, data)
            : engine.quick(quickId, data);
        coachEntry = CoachEntry(
          id: answerId,
          isUser: false,
          origin: stopped == null ? 'rules' : 'safety',
          text: answer.text,
          stats: answer.stats,
          advice: answer.advice,
        );
      }
      assertActive();
      await store.appendMessage(
        userId,
        _toMessage(coachEntry, _clock(), role: 'assistant', answer: answer),
      );
      if (inactive || myGeneration != _generation) return;
      _pending = null;
      emit(
        state.copyWith(
          thinking: false,
          hasRecords: data.meals.isNotEmpty,
          entries: [
            for (final entry in state.entries)
              entry.id == userEntry.id
                  ? entry.copyWith(persisted: true)
                  : entry,
            coachEntry.copyWith(persisted: true),
          ],
        ),
      );
    } catch (_) {
      if (inactive || myGeneration != _generation) return;
      emit(
        state.copyWith(
          thinking: false,
          sendFailure: true,
          entries: [
            for (final entry in state.entries)
              entry.id == userEntry.id ? entry.copyWith(failed: true) : entry,
          ],
        ),
      );
    }
  }

  String _quickLabel(String quickId) {
    final ar = locale == 'ar';
    switch (quickId) {
      case 'plan_tomorrow':
        return ar ? 'اعمل لي خطة غدا' : 'Make me a plan for tomorrow';
      case 'analyze_week':
        return ar ? 'حلل أسبوعي' : 'Analyze my week';
      default:
        return ar ? 'أشرب كام مية؟' : 'How much water should I drink?';
    }
  }

  ChatMessageModel _toMessage(
    CoachEntry entry,
    DateTime at, {
    required String role,
    CoachAnswer? answer,
  }) => ChatMessageModel(
    messageId: entry.id,
    role: role,
    content: entry.text,
    messageType: 'text',
    metadata: {
      'engine': entry.origin,
      if (entry.localRecordSummary) 'localRecordSummary': true,
      if (entry.sourceIds.isNotEmpty) 'sourceIds': entry.sourceIds,
      if (entry.stats.isNotEmpty)
        'stats': [
          for (final stat in entry.stats)
            {'label': stat.label, 'value': stat.value},
        ],
      if (entry.advice != null) 'advice': entry.advice,
    },
    createdAt: at,
  );
}
