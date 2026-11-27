import '../../core/widgets/sufra_button_response.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/nebula_background.dart';
import '../../data/models/food_catalog_model.dart';
import '../../data/repositories/food_repository.dart';
import '../../l10n/app_localizations.dart';
import '../meal_log/domain/catalog_meal_draft.dart';
import '../meal_log/domain/food_portion.dart';
import '../meal_log/domain/meal_review_input.dart';
import '../meal_log/presentation/screens/food_search_screen.dart';
import '../meal_log/presentation/screens/meal_review_screen.dart';
import 'data/dictation_service.dart';
import 'voice_food_suggestions.dart';

class VoiceMealScreen extends StatefulWidget {
  const VoiceMealScreen({super.key, this.dictation});
  static const routePath = '/voice-meal';
  final DictationService? dictation;
  @override
  State<VoiceMealScreen> createState() => _VoiceMealScreenState();
}

class _VoiceMealScreenState extends State<VoiceMealScreen>
    with WidgetsBindingObserver {
  late final DictationService _dictation;
  late final int _lease;
  final _text = TextEditingController();
  final _selected = <String, FoodCatalogModel>{};
  String _seen = '', _mealType = 'lunch';
  bool _searching = false, _searched = false, _failed = false, _edited = false;
  List<FoodCatalogModel> _foods = const [];
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _dictation = widget.dictation ?? PlatformDictationService.shared;
    _lease = _dictation.acquire();
    _dictation.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    if (!mounted) return;
    if (_dictation.text != _seen) {
      _seen = _dictation.text;
      if (!_edited) {
        _text.value = TextEditingValue(
          text: _seen,
          selection: TextSelection.collapsed(offset: _seen.length),
        );
      }
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _dictation.stop(_lease);
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _dictation.removeListener(_changed);
    _dictation.release(_lease);
    _text.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_dictation.status == DictationStatus.listening ||
        _dictation.status == DictationStatus.starting) {
      await _dictation.stop(_lease);
    } else {
      _edited = false;
      await _dictation.start(
        _lease,
        Localizations.localeOf(context).languageCode,
      );
    }
  }

  Future<void> _search() async {
    final text = _text.text.trim();
    if (text.isEmpty || text.length > 1000 || _searching) return;
    await _dictation.stop(_lease);
    if (!mounted) return;
    final generation = ++_generation;
    setState(() {
      _searching = true;
      _failed = false;
      _searched = true;
      _selected.clear();
      _foods = const [];
    });
    try {
      final foods = await VoiceFoodSuggestions(
        context.read<FoodRepository>(),
      ).find(text);
      if (mounted && generation == _generation) {
        setState(() {
          _foods = foods;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _failed = true;
        });
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  Future<void> _manual() async {
    await _dictation.stop(_lease);
    if (!mounted) return;
    final food = await context.push<FoodCatalogModel>(
      FoodSearchScreen.pickRoutePath,
    );
    if (mounted && food != null) {
      setState(() {
        _selected[food.foodId] = food;
        if (!_foods.any((f) => f.foodId == food.foodId)) {
          _foods = [..._foods, food];
        }
      });
    }
  }

  Future<void> _review() async {
    await _dictation.stop(_lease);
    if (!mounted || _selected.isEmpty) return;
    await context.push(
      MealReviewScreen.routePath,
      extra: MealReviewInput(
        inputMethod: 'voice',
        draft: CatalogMealDraft([
          for (final food in _selected.values) FoodPortion(food, 100),
        ]),
        mealType: _mealType,
        notes: _text.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), status = _dictation.status;
    final listening = status == DictationStatus.listening,
        starting = status == DictationStatus.starting;
    final statusText = switch (status) {
      DictationStatus.listening => l.voiceListening,
      DictationStatus.starting => l.voiceStarting,
      DictationStatus.denied => l.voiceDenied,
      DictationStatus.unavailable => l.voiceUnavailable,
      DictationStatus.languageUnavailable => l.voiceLanguageUnavailable,
      DictationStatus.noSpeech => l.voiceNoSpeech,
      DictationStatus.failed => l.voiceFailed,
      _ => l.voiceReady,
    };
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const BackButtonIcon(),
                  ),
                  Expanded(
                    child: Text(
                      l.logHubVoiceTitle,
                      // The bundled display face has colliding Arabic glyphs in
                      // this long heading. Keep the owner's selected face,
                      // but use the bundled body face for fallback review.
                      style: context
                          .displayStyle(size: 25)
                          .copyWith(
                            fontFamily:
                                AppTheme.displayFontFamily == 'Reem Kufi'
                                ? AppTheme.fontFamily
                                : AppTheme.displayFontFamily,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GlassCard(
                borderColor: AppColors.orangeLight.withValues(alpha: .5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SufraControlFeedback(
                        radius: 99,
                        intensity: .35,
                        enabled: !_searching,
                        child: IconButton.filled(
                          onPressed: _searching ? null : _toggle,
                          iconSize: 46,
                          padding: const EdgeInsets.all(22),
                          tooltip: listening || starting
                              ? l.voiceStop
                              : l.voiceStart,
                          icon: Icon(
                            listening || starting
                                ? Icons.stop_rounded
                                : Icons.mic_none_rounded,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(statusText, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    Text(l.voicePrivacy, style: context.explainStyle(size: 12, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _text,
                      enabled: !listening && !starting && !_searching,
                      maxLength: 1000,
                      minLines: 3,
                      maxLines: 6,
                      onChanged: (_) {
                        _edited = true;
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: l.voiceTextHint,
                        helperText: l.voiceDescription,
                        helperMaxLines: 3,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final entry in {
                          'breakfast': l.mealBreakfast,
                          'lunch': l.mealLunch,
                          'dinner': l.mealDinner,
                          'snack': l.mealSnack,
                        }.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: _mealType == entry.key,
                            onSelected: !_searching
                                ? (_) => setState(() {
                                    _mealType = entry.key;
                                  })
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: l.voiceFindFoods,
                      onPressed:
                          !listening &&
                              !starting &&
                              !_searching &&
                              _text.text.trim().isNotEmpty &&
                              _text.text.length <= 1000
                          ? _search
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(l.voicePortionWarning, style: context.mutedStyle()),
              if (_searching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (_failed) Text(l.stateError),
              if (_searched && !_searching && !_failed && _foods.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(l.voiceNoFoods),
                ),
              for (final food in _foods)
                CheckboxListTile(
                  value: _selected.containsKey(food.foodId),
                  title: Text(food.name),
                  subtitle: Text(food.source ?? l.foodUnknown),
                  onChanged: _searching
                      ? null
                      : (value) => setState(() {
                          value == true
                              ? _selected[food.foodId] = food
                              : _selected.remove(food.foodId);
                        }),
                ),
              TextButton.icon(
                onPressed: !_searching && !listening && !starting
                    ? _manual
                    : null,
                icon: const Icon(Icons.search),
                label: Text(l.cameraManual),
              ),
              if (_selected.isNotEmpty)
                GradientButton(
                  label: l.mealReviewTitle,
                  onPressed: !_searching ? _review : null,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
