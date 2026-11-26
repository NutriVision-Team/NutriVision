import '../../../../core/widgets/catalog_food_art.dart';
import '../../../../core/widgets/catalog_photo.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'ramadan_atmosphere.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../planning_shared/presentation/planning_widgets.dart';
import '../../domain/ramadan_logic.dart';
import '../cubit/ramadan_cubit.dart';

/// Screen 29 — Ramadan (رمضان كريم).
class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key, required this.cubit});

  static const routePath = '/ramadan';

  final RamadanCubit cubit;

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.cubit.state.status == RamadanStatus.loading) {
      widget.cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<RamadanCubit, RamadanState>(
        builder: (context, state) {
          switch (state.status) {
            case RamadanStatus.loading:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case RamadanStatus.error:
              return Scaffold(
                body: PlanningError(
                  onRetry: () => context.read<RamadanCubit>().load(),
                ),
              );
            case RamadanStatus.ready:
              return _RamadanBody(state: state);
          }
        },
      ),
    );
  }
}

class _RamadanBody extends StatefulWidget {
  const _RamadanBody({required this.state});

  final RamadanState state;

  @override
  State<_RamadanBody> createState() => _RamadanBodyState();
}

class _RamadanBodyState extends State<_RamadanBody> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _now = context.read<RamadanCubit>().now;
    // The countdown is a live clock; one tick per second, paused when the
    // platform asks for reduced motion (time still updates on rebuilds).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = context.read<RamadanCubit>().now);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final times = state.times;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _RamadanBackground(),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: RamadanAtmosphere(),
          ),
          Positioned.fill(
            bottom: FloatingGlassNavBar.contentClearance(context),
            child: SafeArea(
              child: times == null
                  ? _TimesSetup(onSaved: () => setState(() {}))
                  : ListView(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        const SizedBox(height: 108),
                        _GoldTitle(l10n.ramadanGreeting),
                        const SizedBox(height: 12),
                        _CountdownRow(now: _now, times: times),
                        const SizedBox(height: 12),
                        _FastingArc(now: _now, times: times),
                        const SizedBox(height: 12),
                        for (var i = 0; i < state.suggestions.length; i++)
                          PlanningEntrance(
                            index: i,
                            child: _SuggestionRow(
                              suggestion: state.suggestions[i],
                              times: times,
                            ),
                          ),
                        const SizedBox(height: 8),
                        _WaterRow(state: state),
                        const SizedBox(height: 8),
                        Text(
                          state.cupsFromUser
                              ? l10n.ramadanCupsUserNote
                              : l10n.ramadanCupsDefaultNote,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.planningMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _openTimesSheet(context, times),
                          icon: Icon(Icons.schedule, size: 18),
                          label: Text(l10n.ramadanEditTimes),
                        ),
                        Text(
                          l10n.ramadanDisclaimer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.planningMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: SafeArea(
              child: FloatingGlassNavBar(
                currentIndex: 0,
                onAdd: () => context.go('/log'),
                items: [
                  NavItem(
                    label: l10n.navHome,
                    icon: Icons.home_outlined,
                    onTap: () => context.go('/home'),
                  ),
                  NavItem(
                    label: l10n.navDiary,
                    icon: Icons.book_outlined,
                    onTap: () => context.go('/diary'),
                  ),
                  NavItem(
                    label: l10n.navProgress,
                    icon: Icons.bar_chart,
                    onTap: () => context.go('/stats'),
                  ),
                  NavItem(
                    label: l10n.navAccount,
                    icon: Icons.person_outline,
                    onTap: () => context.go('/profile'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTimesSheet(BuildContext context, RamadanTimes current) {
    return showSufraBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<RamadanCubit>(),
        child: _TimesSheet(current: current),
      ),
    );
  }
}

class _RamadanBackground extends StatelessWidget {
  const _RamadanBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.6, -1),
              radius: 1.2,
              colors: isDark
                  ? const [Color(0xFF5A2F10), AppColors.darkBackground]
                  : const [Color(0xFFFFE4C2), AppColors.lightBackground],
              stops: const [0, 0.72],
            ),
          ),
        ),
        if (isDark) ...[
          _blob(const Alignment(0.9, -0.85), AppColors.aiPurple, 220),
          _blob(const Alignment(-0.95, 0.4), AppColors.turquoise, 240),
          _blob(
            const Alignment(0.85, 0.05),
            AppColors.copper.withValues(alpha: 0.35),
            140,
          ),
        ],
        // The design's Ramadan art fading into the background.
        Align(
          alignment: Alignment.topCenter,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.black, Colors.transparent],
              stops: [0, 0.55, 1],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/art/ram.jpg',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _blob(Alignment alignment, Color color, double size) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _GoldTitle extends StatelessWidget {
  const _GoldTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        // The artwork behind the title stays dark in both themes.
        colors: const [Color(0xFFFDE68A), AppColors.copper, Color(0xFFFDE68A)],
      ).createShader(rect),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: Localizations.localeOf(context).languageCode == "en"
              ? 28
              : 36,
          height: 1.2,
          fontFamily: Localizations.localeOf(context).languageCode == "en"
              ? AppTheme.fontFamily
              : AppTheme.displayFontFamily,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  const _CountdownRow({required this.now, required this.times});

  final DateTime now;
  final RamadanTimes times;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (target, at) = RamadanClock.nextEvent(now, times);
    final remaining = at.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    final targetLabel = switch (target) {
      RamadanCountdownTarget.iftar => l10n.ramadanUntilIftar,
      RamadanCountdownTarget.taraweeh => l10n.ramadanUntilTaraweeh,
      RamadanCountdownTarget.suhoor => l10n.ramadanUntilSuhoor,
    };
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xDE172136),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            targetLabel,
            style: const TextStyle(
              color: Color(0xFFFFE4A3),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _cell(context, seconds, l10n.ramadanSeconds),
            const SizedBox(width: 8),
            _cell(context, minutes, l10n.ramadanMinutes),
            const SizedBox(width: 8),
            _cell(context, hours, l10n.ramadanHours),
          ],
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, int value, String label) {
    return Expanded(
      child: GlassCard(
        borderColor: AppColors.orangeLight.withValues(alpha: .5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          children: [
            Text(
              planningNumber(context, value),
              style: TextStyle(
                fontSize: 30,
                fontFamily: AppTheme.displayFontFamily,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.orangeLight
                    : const Color(0xFF9A4A0A),
              ),
            ),
            Text(
              label,
              style: TextStyle(color: context.planningMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FastingArc extends StatelessWidget {
  const _FastingArc({required this.now, required this.times});

  final DateTime now;
  final RamadanTimes times;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = RamadanClock.fastingProgress(now, times);
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          SizedBox(
            height: 76,
            width: double.infinity,
            child: CustomPaint(
              painter: _ArcPainter(progress),
              size: const Size(300, 76),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            children: [
              Text(
                '${l10n.ramadanSuhoorEnd} ${_formatMinutes(context, times.suhoorEndMinutes)}',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE0E5EF)
                      : const Color(0xFF465062),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${l10n.ramadanIftarAt} ${_formatMinutes(context, times.iftarMinutes)}',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.orangeLight
                      : const Color(0xFF9A4A0A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The design's fasting arc: a shallow curve with a glowing dot at the
/// current position.
class _ArcPainter extends CustomPainter {
  _ArcPainter(this.progress);

  final double progress;

  Offset _point(double t, Size size) {
    // Quadratic bezier matching the HTML path M12 58 Q150 -34 288 58.
    final p0 = Offset(12, size.height - 6);
    final p1 = Offset(size.width / 2, -34);
    final p2 = Offset(size.width - 12, size.height - 6);
    final a = Offset.lerp(p0, p1, t)!;
    final b = Offset.lerp(p1, p2, t)!;
    return Offset.lerp(a, b, t)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(12, size.height - 6);
    for (var i = 1; i <= 40; i++) {
      path.lineTo(_point(i / 40, size).dx, _point(i / 40, size).dy);
    }
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawPath(path, track);

    final progressPath = Path()..moveTo(12, size.height - 6);
    final clamped = progress.clamp(0.0, 1.0);
    for (var i = 1; i <= (40 * clamped).floor(); i++) {
      final t = i / 40;
      progressPath.lineTo(_point(t, size).dx, _point(t, size).dy);
    }
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.copper
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawPath(progressPath, fill);

    if (clamped > 0 && clamped < 1) {
      final dot = _point(clamped, size);
      final glow = Paint()
        ..color = const Color(0xFFFDE68A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(dot, 9, glow);
      canvas.drawCircle(dot, 9, Paint()..color = const Color(0xFFFDE68A));
    }
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.times});

  final RamadanSuggestion suggestion;
  final RamadanTimes times;

  @override
  Widget build(BuildContext context) {
    final title = context.isArabic ? suggestion.titleAr : suggestion.titleEn;
    final timeMinutes = switch (suggestion.slot) {
      'iftar' => times.iftarMinutes,
      'taraweeh' => times.taraweehMinutes,
      _ => times.suhoorEndMinutes,
    };
    final icon = planningIconFor(
      suggestion.items.isEmpty ? '' : suggestion.items.first.category,
    );
    final pictured = suggestion.items.where(
      (item) => CatalogPhoto.forFood(item.foodId) != null,
    );
    final picturedId = pictured.isEmpty ? null : pictured.first.foodId;
    final large = MediaQuery.textScalerOf(context).scale(11) > 15;
    Widget flexible(Widget child) => large ? child : Expanded(child: child);
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      child: Flex(
        direction: large ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: large
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          picturedId != null
              ? IgnorePointer(child: CatalogFoodArt(id: picturedId, size: 48))
              : PlanningMealIcon(icon: icon, size: 40),
          const SizedBox(width: 12),
          flexible(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  _itemNames(context),
                  maxLines: large ? null : 1,
                  overflow: large ? null : TextOverflow.ellipsis,
                  style: TextStyle(color: context.planningMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                planningNumber(context, suggestion.calories),
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: AppTheme.displayFontFamily,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.orangeLight,
                ),
                child: Text(
                  _formatMinutes(context, timeMinutes),
                  style: const TextStyle(
                    color: AppColors.darkBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _itemNames(BuildContext context) {
    if (suggestion.items.isEmpty) return context.l10n.foodUnknown;
    final separator = context.isArabic ? ' و' : ' and ';
    final names = suggestion.items
        .map((item) => context.isArabic ? item.nameAr : item.nameEn)
        .toList(growable: false);
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join('، ')}$separator${names.last}';
  }
}

class _WaterRow extends StatelessWidget {
  const _WaterRow({required this.state});

  final RamadanState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            Wrap(
              children: [
                for (var i = 0; i < state.cupsTarget; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 3),
                    child: _GlassIcon(filled: i < state.filledCups),
                  ),
              ],
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${planningNumber(context, state.filledCups)} / ${planningNumber(context, state.cupsTarget)} ${l10n.ramadanCups}',
                style: TextStyle(color: context.planningMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 30),
      painter: _GlassPainter(filled, context.planningMuted),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final Color outlineColor;
  _GlassPainter(this.filled, this.outlineColor);

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..moveTo(2, 2)
      ..lineTo(size.width - 2, 2)
      ..lineTo(size.width - 3.5, size.height - 2)
      ..lineTo(3.5, size.height - 2)
      ..close();
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.1),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = outlineColor.withValues(alpha: 0.8),
    );
    canvas.drawOval(
      Rect.fromLTWH(2, 0, size.width - 4, 4),
      Paint()
        ..color = outlineColor.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (filled) {
      final waterTop = size.height * 0.35;
      final water = Path()
        ..moveTo(3, waterTop)
        ..lineTo(size.width - 3, waterTop)
        ..lineTo(size.width - 3.8, size.height - 3)
        ..lineTo(3.8, size.height - 3)
        ..close();
      canvas.drawPath(water, Paint()..color = const Color(0xFF22D3EE));
    }
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) =>
      oldDelegate.filled != filled || oldDelegate.outlineColor != outlineColor;
}

/// First-run state: no times are configured, and the app never invents
/// prayer times, so the user sets their own.
class _TimesSetup extends StatelessWidget {
  const _TimesSetup({required this.onSaved});

  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          borderColor: AppColors.orangeLight.withValues(alpha: .5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GoldTitle(l10n.ramadanGreeting),
              const SizedBox(height: 12),
              Text(
                l10n.ramadanSetupBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.planningMuted, height: 1.8),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await showSufraBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => BlocProvider.value(
                      value: context.read<RamadanCubit>(),
                      child: const _TimesSheet(),
                    ),
                  );
                  onSaved();
                },
                child: Text(l10n.ramadanSetupCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimesSheet extends StatefulWidget {
  const _TimesSheet({this.current});

  final RamadanTimes? current;

  @override
  State<_TimesSheet> createState() => _TimesSheetState();
}

class _TimesSheetState extends State<_TimesSheet> {
  late int? _iftar = widget.current?.iftarMinutes;
  late int? _suhoor = widget.current?.suhoorEndMinutes;
  late int? _taraweeh = widget.current?.taraweehMinutes;
  bool _saving = false;

  Future<void> _pick(void Function(int minutes) apply, int? initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked != null) {
      setState(() => apply(picked.hour * 60 + picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.ramadanTimesTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ramadanTimesNote,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.planningMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _timeRow(
            l10n.ramadanSuhoorEnd,
            _suhoor,
            () => _pick((m) => _suhoor = m, _suhoor),
          ),
          _timeRow(
            l10n.ramadanIftarAt,
            _iftar,
            () => _pick((m) => _iftar = m, _iftar),
          ),
          _timeRow(
            l10n.ramadanTaraweeh,
            _taraweeh,
            () => _pick((m) => _taraweeh = m, _taraweeh),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _saving ||
                      _iftar == null ||
                      _suhoor == null ||
                      _taraweeh == null
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      final saved = await context
                          .read<RamadanCubit>()
                          .saveTimes(
                            RamadanTimes(
                              iftarMinutes: _iftar!,
                              suhoorEndMinutes: _suhoor!,
                              taraweehMinutes: _taraweeh!,
                            ),
                          );
                      if (!context.mounted) return;
                      setState(() => _saving = false);
                      if (saved) Navigator.of(context).pop();
                    },
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.actionSave),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRow(String label, int? minutes, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(
          minutes == null
              ? context.l10n.ramadanChooseTime
              : _formatMinutes(context, minutes),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      onTap: onTap,
    );
  }
}

String _formatMinutes(BuildContext context, int minutes) {
  final hour24 = minutes ~/ 60;
  final minute = minutes % 60;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final period = hour24 < 12
      ? (isArabic ? 'ص' : 'AM')
      : (isArabic ? 'م' : 'PM');
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final digits = '${hour12.toString()}:${minute.toString().padLeft(2, '0')}';
  final localized = isArabic
      ? digits
            .split('')
            .map(
              (c) => '0123456789'.contains(c) ? '٠١٢٣٤٥٦٧٨٩'[int.parse(c)] : c,
            )
            .join()
      : digits;
  return '$localized $period';
}
