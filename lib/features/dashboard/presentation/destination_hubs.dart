import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/nebula_background.dart';
import '../../../core/widgets/sufra_navigation.dart';
import '../../../core/widgets/language_settings.dart';
import '../../../core/widgets/theme_switcher.dart';
import '../../../core/widgets/sufra_dialog.dart';
import '../../auth/presentation/cubit/session_cubit.dart';
import '../../auth/presentation/personal_educational_policy.dart';
import '../../home/presentation/widgets/local_profile_avatar.dart';

class MealsHubScreen extends StatelessWidget {
  const MealsHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return DestinationScaffold(
      index: 1,
      title: ar ? 'وجباتك، في مكان واحد' : 'Your meals, in one place',
      subtitle: ar
          ? 'اكتشف وصفة، رتّب أسبوعك، وراجع سجلك.'
          : 'Find a recipe, plan your week, and review your diary.',
      children: [
        for (final entry in [
          (
            Icons.menu_book_outlined,
            ar ? 'سجل الوجبات' : 'Meal diary',
            ar
                ? 'وجباتك حسب اليوم، مع التعديل والحذف'
                : 'Your daily meals, with edit and delete',
            '/diary',
          ),
          (
            Icons.restaurant_menu,
            ar ? 'اكتشف الوصفات' : 'Discover recipes',
            ar
                ? 'وصفات بمصادرها وتصنيفاتها الأصلية'
                : 'Recipes with their original sources and categories',
            '/recipes',
          ),
          (
            Icons.search,
            ar ? 'ابحث عن طعام' : 'Search foods',
            ar
                ? 'اختار الكمية وراجع القيم قبل التسجيل'
                : 'Choose a portion and review nutrition before saving',
            '/food-search',
          ),
          (
            Icons.calendar_month_outlined,
            ar ? 'خطة الأسبوع' : 'Weekly planner',
            ar
                ? 'رتّب الوجبات اللي تناسبك'
                : 'Organize the meals that suit you',
            '/planner',
          ),
          (
            Icons.favorite_outline,
            ar ? 'المفضلة' : 'Favorites',
            ar ? 'وصفات وأطعمة حفظتها بنفسك' : 'Recipes and foods you saved',
            '/favorites',
          ),
          (
            Icons.shopping_bag_outlined,
            ar ? 'قائمة المشتريات' : 'Shopping list',
            ar ? 'احتياجاتك للأسبوع' : 'What you need for the week',
            '/shopping',
          ),
        ])
          _DestinationTile(
            icon: entry.$1,
            title: entry.$2,
            subtitle: entry.$3,
            onTap: () => context.push(entry.$4),
          ),
      ],
    );
  }
}

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        final profile = session is SessionAuthenticated
            ? session.profile
            : null;
        final uid = session is SessionAuthenticated ? session.user.uid : '';
        return DestinationScaffold(
          index: 3,
          title: ar ? 'حسابي' : 'My profile',
          subtitle: ar
              ? 'بياناتك وتفضيلاتك، تحت سيطرتك.'
              : 'Your details and preferences, in your control.',
          children: [
            GlassCard(
              child: Row(
                children: [
                  if (uid.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orangeDeep.withValues(alpha: .45),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: LocalProfileAvatar(uid: uid),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ??
                              (ar ? 'حسابك' : 'Your account'),
                          style: context.displayStyle(size: 22),
                        ),
                        if (profile?.email != null)
                          Text(
                            profile!.email!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.mutedStyle(),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          ar
                              ? 'الصورة محفوظة على الجهاز فقط'
                              : 'Profile photo is stored on this device only',
                          style: context.mutedStyle(size: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _DestinationTile(
              icon: Icons.auto_awesome,
              title: ar ? 'مدربي الصحي' : 'My health coach',
              subtitle: ar ? 'افتح مساعد سفرة' : 'Open the Sufra assistant',
              onTap: () => context.push('/coach'),
            ),
            _DestinationTile(
              icon: Icons.monitor_heart_outlined,
              title: ar ? 'الأهداف والسجل الصحي' : 'Goals and health records',
              subtitle: ar
                  ? 'راجع خطتك وقياساتك المسجلة'
                  : 'Review your plan and recorded measurements',
              onTap: () => context.push('/nutrition-stats'),
            ),
            _DestinationTile(
              icon: Icons.notifications_outlined,
              title: ar ? 'التذكيرات' : 'Reminders',
              subtitle: ar
                  ? 'إعدادات التنبيهات المحلية'
                  : 'Local notification settings',
              onTap: () => context.push('/reminders'),
            ),
            _DestinationTile(
              icon: Icons.workspace_premium_outlined,
              title: ar ? 'سفرة بريميوم' : 'Sufra Premium',
              subtitle: ar ? 'اعرف اللي جاي قريبًا' : 'See what is coming soon',
              onTap: () => context.push('/premium'),
            ),
            _DestinationTile(
              icon: Icons.translate,
              title: ar ? 'اللغة' : 'Language',
              subtitle: ar ? 'العربية / English' : 'English / العربية',
              onTap: () => showLanguageSettings(context),
            ),
            GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ar ? 'المظهر' : 'Appearance',
                      style: context.displayStyle(size: 18),
                    ),
                  ),
                  const LiquidThemeButton(),
                ],
              ),
            ),
            _DestinationTile(
              icon: Icons.privacy_tip_outlined,
              title: ar ? 'الخصوصية والاستخدام' : 'Privacy and use',
              subtitle: ar
                  ? 'اقرأ النص المعتمد للتطبيق'
                  : 'Read the app policy',
              onTap: () => showSufraDialog<void>(
                context: context,
                builder: (_) => SufraAlertDialog(
                  title: Text(ar ? 'الخصوصية والاستخدام' : 'Privacy and use'),
                  content: const SingleChildScrollView(
                    child: Text(personalEducationalPolicyTextAr),
                  ),
                ),
              ),
            ),
            _DestinationTile(
              icon: Icons.logout,
              title: ar ? 'تسجيل الخروج' : 'Log out',
              subtitle: ar
                  ? 'اخرج من حسابك على الجهاز ده'
                  : 'Sign out of your account on this device',
              onTap: () async {
                final cubit = context.read<SessionCubit>();
                final confirmed = await showSufraDialog<bool>(
                  context: context,
                  builder: (dialogContext) => SufraAlertDialog(
                    title: Text(ar ? 'تسجيل الخروج؟' : 'Log out?'),
                    content: Text(
                      ar
                          ? 'هتخرج من حسابك على الجهاز ده. بياناتك محفوظة وتقدر ترجع تدخل في أي وقت.'
                          : 'You will be signed out on this device. Your data is kept and you can sign back in anytime.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(ar ? 'إلغاء' : 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(ar ? 'تسجيل الخروج' : 'Log out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await cubit.signOut();
              },
            ),
          ],
        );
      },
    );
  }
}

class DestinationScaffold extends StatelessWidget {
  const DestinationScaffold({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final int index;
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: false,
    body: NebulaBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Text(title, style: context.displayStyle(size: 28)),
            const SizedBox(height: 6),
            Text(subtitle, style: context.mutedStyle()),
            const SizedBox(height: 22),
            for (var i = 0; i < children.length; i++)
              _Reveal(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: children[i],
                ),
              ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SufraNavigation(currentIndex: index),
    ),
  );
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withValues(alpha: .28),
                AppColors.orangeDeep.withValues(alpha: .22),
              ],
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: .6)),
            boxShadow: [
              BoxShadow(
                color: AppColors.orangeDeep.withValues(alpha: .25),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.gold
                : AppColors.orangeDeep,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.displayStyle(size: 18)),
              const SizedBox(height: 4),
              Text(subtitle, style: context.mutedStyle(size: 13)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left
              : Icons.chevron_right,
          size: 20,
        ),
      ],
    ),
  );
}

/// Staggered fade and rise on entry; no motion when animations are disabled.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 22), child: c),
      ),
      child: child,
    );
  }
}
