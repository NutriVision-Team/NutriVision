import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../../core/widgets/sufra_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/local_avatar_store.dart';

class LocalProfileAvatar extends StatefulWidget {
  const LocalProfileAvatar({
    super.key,
    required this.uid,
    this.store = const LocalAvatarStore(),
    this.pick,
    this.editable = true,
    this.size = 54,
  });
  final bool editable;
  final double size;
  final String uid;
  final LocalAvatarStore store;
  final Future<String?> Function()? pick;
  @override
  State<LocalProfileAvatar> createState() => _LocalProfileAvatarState();
}

class _LocalProfileAvatarState extends State<LocalProfileAvatar> {
  Uint8List? _bytes;
  bool _busy = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LocalProfileAvatar old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid) {
      _bytes = null;
      _load();
    }
  }

  bool _active(String uid) =>
      mounted &&
      widget.uid == uid &&
      switch (context.read<SessionCubit>().state) {
        SessionAuthenticated(user: final user) => user.uid == uid,
        _ => false,
      };
  Future<void> _load() async {
    final generation = ++_generation, uid = widget.uid;
    try {
      final bytes = await widget.store.readBytes(uid);
      if (_active(uid) && generation == _generation) {
        setState(() => _bytes = bytes);
      }
    } catch (_) {
      /* Placeholder is safe when a local file is absent. */
    }
  }

  Future<void> _choose() async {
    if (_busy) return;
    final uid = widget.uid;
    final l = AppLocalizations.of(context);
    final approved = await showSufraDialog<bool>(
      context: context,
      builder: (context) => SufraAlertDialog(
        content: Text(l.avatarLocalNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.avatarChoose),
          ),
        ],
      ),
    );
    if (approved != true || !_active(uid)) return;
    setState(() => _busy = true);
    try {
      final source = await (widget.pick?.call() ?? _pick());
      if (source == null || !_active(uid)) return;
      await widget.store.save(uid, source, active: () => _active(uid));
      if (!_active(uid)) return;
      final bytes = await widget.store.readBytes(uid);
      if (_active(uid)) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted && _active(uid)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SufraSnackBar(content: Text(l.avatarFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _pick() async => (await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  ))?.path;
  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: AppLocalizations.of(context).avatarChoose,
    child: InkWell(
      onTap: _busy || !widget.editable ? null : _choose,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.goldDeep, Color(0xFF37B9A7)],
          ),
        ),
        child: _busy
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _bytes == null
            ? Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF12343A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.gold,
                  size: widget.size * .7,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _bytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SufraLogo(size: 46),
                ),
              ),
      ),
    ),
  );
}
