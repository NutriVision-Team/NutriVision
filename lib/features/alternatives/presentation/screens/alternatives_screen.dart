import '../../../../core/widgets/sufra_button_response.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import '../../../../core/widgets/catalog_food_art.dart';
import '../../../../data/models/nutrition_profile_model.dart';
import '../../domain/food_preference_filter.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/alternatives_repository.dart';
import '../../../recipes/presentation/widgets/discovery_widgets.dart';

Color _alternativeCyan(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.cyanLight
    : const Color(0xFF087A8C);
Color _alternativeGreen(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.greenLight
    : const Color(0xFF15723B);
Color _alternativePurple(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.purpleLight
    : const Color(0xFF6D35AD);

class AlternativesScreen extends StatefulWidget {
  const AlternativesScreen({super.key, this.repository, this.loadProfile});
  static const routePath = '/alternatives';
  final AlternativesRepository? repository;
  final Future<NutritionProfileModel?> Function()? loadProfile;
  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  late Future<List<FoodAlternative>> _load;
  NutritionProfileModel? _profile;
  int _generation = 0;
  final _query = TextEditingController();
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _profile = null;
    _load = _loadOwned(++_generation);
  }

  Future<List<FoodAlternative>> _loadOwned(int version) async {
    final loader = widget.loadProfile;
    final values = await Future.wait<Object?>([
      (widget.repository ?? AlternativesRepository()).getAll(),
      if (loader != null) loader() else Future<NutritionProfileModel?>.value(),
    ]);
    if (!mounted || version != _generation) return const [];
    _profile = values[1] as NutritionProfileModel?;
    return (values[0] as List<FoodAlternative>)
        .where(
          (r) => FoodPreferenceFilter.allows(
            r.alternative,
            allergies: _profile?.allergies ?? const [],
            dietaryPreferences: _profile?.dietaryPreferences ?? const [],
          ),
        )
        .toList(growable: false);
  }

  @override
  void didUpdateWidget(covariant AlternativesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.loadProfile != widget.loadProfile) {
      _reload();
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DiscoveryScaffold(
    child: FutureBuilder<List<FoodAlternative>>(
      future: _load,
      builder: (context, snapshot) {
        final records = AlternativesRepository.filter(
          snapshot.data ?? [],
          _query.text,
        );
        return DiscoveryList(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  icon: const BackButtonIcon(),
                ),
                Expanded(
                  child: DiscoveryTitle(
                    AppLocalizations.of(context).discoveryMsg052,
                  ),
                ),
              ],
            ),
            DiscoveryNotice(
              AppLocalizations.of(context).alternativesPreferenceNote,
            ),
            if (_profile != null &&
                (_profile!.allergies.isNotEmpty ||
                    _profile!.dietaryPreferences.isNotEmpty))
              Text(
                [
                  ..._profile!.allergies,
                  ..._profile!.dietaryPreferences,
                ].join(' · '),
              ),
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).discoveryMsg053,
                suffixIcon: _query.text.isEmpty
                    ? Icon(Icons.search, color: _alternativeCyan(context))
                    : IconButton(
                        tooltip: AppLocalizations.of(context).discoveryMsg034,
                        onPressed: () => setState(_query.clear),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              DiscoveryError(onRetry: () => setState(_reload))
            else if (records.isEmpty)
              GlassCard(
                child: Text(AppLocalizations.of(context).discoveryMsg054),
              )
            else ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context).discoveryMsg055,
                      style: TextStyle(
                        color: _alternativePurple(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DiscoveryNotice(
                      AppLocalizations.of(context).discoveryMsg056,
                    ),
                  ],
                ),
              ),
              for (final (index, record) in records.indexed)
                DiscoveryEntrance(
                  index: index,
                  child: _AlternativeCard(record: record),
                ),
            ],
            DiscoveryTitle(
              AppLocalizations.of(context).discoveryMsg057,
              size: 18,
            ),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: _alternativeCyan(context),
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).discoveryMsg058),
                  DiscoveryNotice(AppLocalizations.of(context).discoveryMsg059),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.record});
  final FoodAlternative record;
  @override
  Widget build(BuildContext context) {
    final ar = discoveryArabic(context);
    final originalName = ar ? record.original.nameAr : record.original.nameEn;
    final alternativeName = ar
        ? record.alternative.nameAr
        : record.alternative.nameEn;
    final from = record.comparisons['energyKcal']?.source;
    final to = record.comparisons['energyKcal']?.alternative;
    final ratio = from != null && to != null && from > 0 && to >= 0
        ? to / (from > to ? from : to)
        : null;
    return SufraControlFeedback(
      radius: 24,
      intensity: .18,
      child: GlassCard(
        borderColor: AppColors.orangeLight.withValues(alpha: .5),
        onTap: () => _details(context),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              originalName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                      bottom: Radius.circular(10),
                    ),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: IgnorePointer(
                    child: CatalogFoodArt(id: record.alternative.id, size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alternativeName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).discoveryMsg060,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: DiscoveryNumberSequence(
                      first: from,
                      second: to,
                      separator: ' → ',
                      unit: AppLocalizations.of(context).foodKcal,
                      style: TextStyle(
                        color: to != null && from != null && to < from
                            ? _alternativeGreen(context)
                            : _alternativeCyan(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (ratio != null)
              LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
                color: to != null && from != null && to < from
                    ? _alternativeGreen(context)
                    : _alternativeCyan(context),
                backgroundColor: Colors.white12,
              ),
            const SizedBox(height: 8),
            Text(
              _readableReason(context, ar ? record.reasonAr : record.reasonEn),
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).discoveryMsg061,
              style: TextStyle(fontSize: 11, color: _alternativeCyan(context)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _details(
    BuildContext parentContext,
  ) => showSufraBottomSheet<void>(
    context: parentContext,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).discoveryMsg062,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              '${AppLocalizations.of(context).discoveryMsg063}: ${discoveryArabic(context) ? record.original.nameAr : record.original.nameEn}',
            ),
            Text(
              '${AppLocalizations.of(context).discoveryMsg064}: ${discoveryArabic(context) ? record.alternative.nameAr : record.alternative.nameEn}',
            ),
            const SizedBox(height: 12),
            for (final entry in record.comparisons.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(_nutrient(context, entry.key))),
                    DiscoveryNumberSequence(
                      first: entry.value.source,
                      second: entry.value.alternative,
                      separator: ' → ',
                    ),
                  ],
                ),
              ),
            const Divider(),
            Text(AppLocalizations.of(context).discoveryMsg065),
            Text(
              '${_foodState(context, record.original.foodState)} / ${_foodState(context, record.alternative.foodState)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
  String _foodState(BuildContext context, String state) {
    if (!discoveryArabic(context)) return state;
    return const {
          'raw': 'نيء',
          'cooked': 'مطهو',
          'prepared': 'جاهز',
          'canned': 'معلب',
          'dried': 'مجفف',
          'fluid': 'سائل',
        }[state] ??
        'مش محدد';
  }

  String _readableReason(BuildContext context, String reason) {
    return reason.replaceAllMapped(
      RegExp(
        r'\b(?:energyKcal|fiberG|fatG|proteinG|carbohydrateG|sugarsG|sodiumMg)\b',
      ),
      (match) => _nutrient(context, match[0]!),
    );
  }

  String _nutrient(BuildContext context, String key) => switch (key) {
    'energyKcal' => AppLocalizations.of(context).discoveryMsg066,
    'fiberG' => AppLocalizations.of(context).discoveryMsg067,
    'fatG' => AppLocalizations.of(context).discoveryMsg068,
    'proteinG' => AppLocalizations.of(context).discoveryMsg069,
    'carbohydrateG' => AppLocalizations.of(context).foodCarbs,
    'sugarsG' => AppLocalizations.of(context).foodSugar,
    'sodiumMg' => AppLocalizations.of(context).foodSodium,
    _ => key,
  };
}
