import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// System back (Android button or gesture) behaviour for the whole app.
///
/// - Dialogs, sheets and pushed pages: left to the router, which pops them.
/// - Wizard step above the first: [stepBack] consumes the press.
/// - Register goes back to login.
/// - Any other signed-in page that has nothing to pop goes to Home. Tabs are
///   reached with `go`, so without this the app would close from them.
/// - Home asks for a second press within two seconds before closing.
///
/// The web uses the browser history, so this guard stays out of its way.
class BackGuard extends StatefulWidget {
  const BackGuard({
    super.key,
    required this.router,
    required this.child,
    this.stepBack,
  });

  final GoRouter router;
  final Widget child;

  /// Returns true when it moved a wizard one step back.
  final bool Function()? stepBack;

  @override
  State<BackGuard> createState() => _BackGuardState();
}

class _BackGuardState extends State<BackGuard> with WidgetsBindingObserver {
  DateTime? _lastHomeBack;

  @override
  void initState() {
    super.initState();
    // Registered before the Router below mounts, so it is asked first.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() => _onBack();

  static const _flow = {
    '/splash',
    '/onboarding',
    '/login',
    '/welcome',
    '/plan',
  };

  Future<bool> _onBack() async {
    if (kIsWeb) return false;
    final nav = widget.router.routerDelegate.navigatorKey.currentState;
    if (nav != null && nav.canPop()) return false;
    final path =
        widget.router.routerDelegate.currentConfiguration.last.matchedLocation;
    if (path == '/setup') {
      return widget.stepBack?.call() ?? false;
    }
    if (path == '/register') {
      widget.router.go('/login');
      return true;
    }
    if (_flow.contains(path)) return false;
    if (path != '/home') {
      widget.router.go('/home');
      return true;
    }
    final now = DateTime.now();
    final last = _lastHomeBack;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return false;
    }
    _lastHomeBack = now;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            ar ? 'اضغط رجوع مرة تانية للخروج' : 'Press back again to exit',
          ),
        ),
      );
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
