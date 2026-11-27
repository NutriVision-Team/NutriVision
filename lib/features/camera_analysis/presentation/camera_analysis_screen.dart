import 'photo_scan_overlay.dart';
import '../../../core/utils/decimal_input.dart';
import '../domain/photo_meal_resolver.dart';
import '../domain/photo_meal_clarification.dart';
import '../../food_catalog/data/datasources/local_food_data_source.dart';
import 'photo_meal_result_card.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/widgets/theme_switcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../voice_logging/presentation/dictation_text_sheet.dart';
import '../data/capture_cleanup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/nebula_background.dart';
import '../../../data/models/food_catalog_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../meal_log/domain/catalog_meal_draft.dart';
import '../../meal_log/domain/food_portion.dart';
import '../../meal_log/domain/meal_review_input.dart';
import '../../meal_log/presentation/screens/food_search_screen.dart';
import '../../meal_log/presentation/screens/meal_review_screen.dart';
import '../data/meal_image_preparer.dart';
import '../domain/food_recognition_provider.dart';
import 'capture_device.dart';
import 'recognition_note_localization.dart';
import 'camera_mode_header.dart';
import 'camera_capture_chrome.dart';

class CameraAnalysisScreen extends StatefulWidget {
  const CameraAnalysisScreen({
    super.key,
    this.device,
    this.returnReviewedDraft = false,
    this.pickGallery,
    this.preparer = const MealImagePreparer(),
    this.provider = const ManualFoodRecognitionProvider(),
  });
  static const routePath = '/camera';
  final bool returnReviewedDraft;
  final CaptureDevice? device;
  final Future<String?> Function()? pickGallery;
  final MealImagePreparer preparer;
  final FoodRecognitionProvider provider;
  @override
  State<CameraAnalysisScreen> createState() => _CameraAnalysisScreenState();
}

class _CameraAnalysisScreenState extends State<CameraAnalysisScreen>
    with WidgetsBindingObserver {
  late final CaptureDevice _device;
  final _notes = TextEditingController();
  final _hints = <int>{};
  PreparedMealImage? _image;
  FoodRecognitionResult? _result;
  final _chosen = <int, FoodPortion>{};
  final _skipped = <int>{};
  FoodPortion? _addedOil;
  final _unconfirmed = <int>{};
  bool _clarificationSkipped = false;
  String _mealType = 'lunch';
  String? _error;
  bool _busy = false, _flash = false, _switchingMode = false;
  double _zoom = 1;
  int _operation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _device = widget.device ?? NativeCaptureDevice();
    _device.addListener(_changed);
    _device.initialize();
  }

  ImagePreparationCancellation? _preparation;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ++_operation;
      _preparation?.cancel();
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
      _device.pause();
    } else if (state == AppLifecycleState.resumed && _image == null) {
      _device.initialize();
    }
  }

  @override
  void dispose() {
    ++_operation;
    _preparation?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _device.removeListener(_changed);
    _device.dispose();
    _notes.dispose();
    _image?.delete();
    super.dispose();
  }

  Future<void> _capture({bool gallery = false}) async {
    if (_busy) return;
    final operation = ++_operation;
    final cancellation = ImagePreparationCancellation();
    _preparation?.cancel();
    _preparation = cancellation;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? source;
    PreparedMealImage? prepared;
    try {
      if (gallery) {
        source = widget.pickGallery != null
            ? await widget.pickGallery!()
            : (await ImagePicker().pickImage(
                source: ImageSource.gallery,
                maxWidth: 1600,
                maxHeight: 1600,
                imageQuality: 85,
              ))?.path;
        if (source == null) return;
      } else {
        source = await _device.capture();
      }
      cancellation.check();
      prepared = await widget.preparer.prepare(
        source,
        cancellation: cancellation,
      );
      if (!mounted || operation != _operation) {
        await prepared.delete();
        return;
      }
      await _device.pause();
      if (!mounted || operation != _operation) {
        await prepared.delete();
        return;
      }
      setState(() {
        _image = prepared;
        _result = null;
        _chosen.clear();
        _addedOil = null;
        _unconfirmed.clear();
        _clarificationSkipped = false;
        _skipped.clear();
        _flash = false;
      });
    } on ImagePreparationException catch (e) {
      if (e.failure == ImagePreparationFailure.cancelled) return;
      if (mounted && operation == _operation) {
        setState(() {
          _error = e.failure == ImagePreparationFailure.tooLarge
              ? 'size'
              : 'image';
        });
      }
    } catch (_) {
      if (mounted && operation == _operation) {
        setState(() {
          _error = 'capture';
        });
      }
    } finally {
      if (identical(_preparation, cancellation)) _preparation = null;
      if (source != null && !gallery) {
        await deleteCapture(source);
      }
      if (mounted && operation == _operation) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _openCaptureMode(String route) async {
    if (_busy || _switchingMode) return;
    _switchingMode = true;
    try {
      await _device.pause();
      if (!mounted) return;
      await context.push(route);
      if (mounted && _image == null) await _device.initialize();
    } finally {
      _switchingMode = false;
    }
  }

  Future<void> _retake() async {
    ++_operation;
    _preparation?.cancel();
    final old = _image;
    setState(() {
      _image = null;
      _result = null;
      _chosen.clear();
      _addedOil = null;
      _unconfirmed.clear();
      _clarificationSkipped = false;
      _skipped.clear();
      _error = null;
      _busy = false;
      _zoom = 1;
    });
    await old?.delete();
    if (mounted) await _device.initialize();
  }

  String _allNotes(AppLocalizations l) => [
    ..._hints.map((i) => _hintLabels(l)[i]),
    if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
  ].join('، ');
  List<String> _hintLabels(AppLocalizations l) => [
    l.cameraNoOil,
    l.cameraLarge,
    l.cameraSmall,
    l.cameraSugar,
    l.cameraGhee,
  ];
  Future<void> _analyze() async {
    final image = _image;
    if (image == null || _busy) return;
    if (!widget.provider.isAvailable) {
      setState(() {
        _error = 'unavailable';
      });
      return;
    }
    final provider = widget.provider;
    final qualification =
        provider is NonpersonalQualificationProvider &&
        provider.permitsImage(image.bytes);
    final personal =
        provider is ConsentGatedFoodRecognitionProvider &&
        provider.acceptsPersonalImages;
    final name = provider is NonpersonalQualificationProvider
        ? provider.providerName
        : provider is ConsentGatedFoodRecognitionProvider
        ? provider.providerName
        : '';
    final disclosure = provider is LocalizedRecognitionDisclosure
        ? (provider as LocalizedRecognitionDisclosure).disclosureFor(
            Localizations.localeOf(context).languageCode,
          )
        : provider is NonpersonalQualificationProvider
        ? provider.processingDisclosure
        : provider is ConsentGatedFoodRecognitionProvider
        ? provider.processingDisclosure
        : '';
    final policy = provider is NonpersonalQualificationProvider
        ? provider.privacyPolicy
        : provider is ConsentGatedFoodRecognitionProvider
        ? provider.privacyPolicy
        : Uri();
    if ((!qualification && !personal) ||
        name.trim().isEmpty ||
        disclosure.trim().isEmpty ||
        policy.scheme != 'https' ||
        policy.host.isEmpty) {
      setState(() => _error = 'unavailable');
      return;
    }
    final permissionOperation = ++_operation;
    final l = AppLocalizations.of(context);
    final approved = await showSufraDialog<bool>(
      context: context,
      builder: (c) => SufraAlertDialog(
        title: Text(
          (qualification ? l.cameraConsentTitle(name) : l.cameraConsentTitleShort),
          style: context.readableDisplayStyle(size: 20),
        ),
        content: _ConsentBody(
          short: qualification
              ? (Localizations.localeOf(context).languageCode == 'ar'
                    ? 'الموافقة للمرة دي بس وعلى الصورة التجريبية المحددة فقط. تقدر تلغي وتضيف وجبتك بنفسك. النتيجة لازم تراجعها قبل الحفظ.'
                    : 'One-time permission for this exact nonpersonal test image only. You can cancel and add your meal yourself. Review the result before saving.')
              : l.cameraConsentShort,
          detailsLabel: l.cameraConsentDetailsToggle,
          disclosure: disclosure,
          policy: policy.toString(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.cameraConsentSend),
          ),
        ],
      ),
    );
    if (!mounted ||
        approved != true ||
        permissionOperation != _operation ||
        !identical(_image, image) ||
        !identical(widget.provider, provider) ||
        !provider.isAvailable ||
        !(provider is NonpersonalQualificationProvider &&
                provider.permitsImage(image.bytes) ||
            provider is ConsentGatedFoodRecognitionProvider &&
                provider.acceptsPersonalImages)) {
      return;
    }
    final operation = ++_operation;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _chosen.clear();
      _addedOil = null;
      _unconfirmed.clear();
      _clarificationSkipped = false;
      _skipped.clear();
    });
    try {
      final result = await widget.provider.recognize(
        FoodRecognitionInput(
          jpegBytes: image.bytes,
          mealType: _mealType,
          notes: _allNotes(AppLocalizations.of(context)),
        ),
      );
      final foods =
          await (result.items.any(
                (i) => i.foodState != null && i.suggestedPortionGrams != null,
              )
              ? LocalFoodDataSource().getAll()
              : Future.value(<LocalFoodRecord>[]));
      final resolved = const PhotoMealResolver().resolve(result, foods);
      if (!mounted || operation != _operation) return;
      setState(() {
        _chosen.addAll(resolved);
        _unconfirmed.addAll(resolved.keys);
        if (result.items.isEmpty) {
          _result = null;
          _chosen.clear();
          _unconfirmed.clear();
          _error = 'empty';
        } else {
          _result = result;
        }
      });
    } on FoodRecognitionException catch (e) {
      if (mounted && operation == _operation) {
        setState(() {
          _error = e.failure.name;
        });
      }
    } catch (_) {
      if (mounted && operation == _operation) {
        setState(() {
          _error = 'network';
        });
      }
    } finally {
      if (mounted && operation == _operation) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _manual() async {
    final notes = _allNotes(AppLocalizations.of(context));
    if (_image == null) await _device.pause();
    if (!mounted) return;
    final food = await context.push<FoodCatalogModel>(
      FoodSearchScreen.pickRoutePath,
    );
    if (!mounted) return;
    if (food != null) {
      if (_result != null) {
        final existing = _chosen.entries
            .where((e) => e.value.food.foodId == food.foodId)
            .firstOrNull;
        if (existing != null) {
          await _editResultPortion(existing.key);
          return;
        }
        setState(() {
          final index = _result!.items.length;
          _result = FoodRecognitionResult(
            items: [
              ..._result!.items,
              RecognitionCandidate(name: food.name, foodState: food.foodState),
            ],
            generalNotes: _result!.generalNotes,
          );
          _chosen[index] = FoodPortion(food, 100);
          _unconfirmed.add(index);
          _addedOil = null;
        });
        return;
      }
      await context.push(
        MealReviewScreen.routePath,
        extra: MealReviewInput(
          inputMethod: 'photo',
          draft: CatalogMealDraft([FoodPortion(food, 100)]),
          mealType: _mealType,
          notes: notes,
        ),
      );
    }
    if (mounted && _image == null) await _device.initialize();
  }

  Future<void> _pickCandidate(int index) async {
    final food = await context.push<FoodCatalogModel>(
      FoodSearchScreen.pickRoutePath,
      extra: _result!.items[index].name,
    );
    if (!mounted || food == null) return;
    setState(() {
      _addedOil = null;
      _chosen[index] = FoodPortion(food, 100);
      _skipped.remove(index);
      _unconfirmed.add(index);
    });
  }

  Future<void> _editResultPortion(int index) async {
    final current = _chosen[index];
    if (current == null) return;
    final controller = TextEditingController(
      text: current.grams.toStringAsFixed(0),
    );
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final grams = await showSufraDialog<double>(
      context: context,
      builder: (c) => SufraAlertDialog(
        title: Text(ar ? 'راجع الجرامات' : 'Review grams'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: 'g',
            helperText: ar
                ? 'الجزء المأكول بس، من غير عضم أو قشر'
                : 'Edible portion only, without bones or peel',
            helperMaxLines: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = parseDecimalInput(controller.text);
              if (v != null && v > 0 && v <= 10000) Navigator.pop(c, v);
            },
            child: Text(ar ? 'تأكيد الكمية' : 'Confirm amount'),
          ),
        ],
      ),
    );
    // Dispose after the closing route transition has released its text field.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    if (!mounted || grams == null) return;
    setState(() {
      _chosen[index] = FoodPortion(current.food, grams);
    });
  }

  void _reviewCandidates() {
    if (_result == null ||
        _unconfirmed.isNotEmpty ||
        _chosen.isEmpty ||
        _chosen.length + _skipped.length != _result!.items.length) {
      return;
    }
    final draft = CatalogMealDraft([
      for (var i = 0; i < _result!.items.length; i++)
        if (_chosen.containsKey(i)) _chosen[i]!,
      if (_addedOil != null) _addedOil!,
    ]);
    if (widget.returnReviewedDraft) {
      context.pop(draft);
      return;
    }
    context.push(
      MealReviewScreen.routePath,
      extra: MealReviewInput(
        inputMethod: 'photo',
        draft: draft,
        mealType: _mealType,
        notes: _allNotes(AppLocalizations.of(context)),
      ),
    );
  }

  Future<void> _clarifyOil() async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final operation = _operation;
    var amount = _addedOil?.grams.toString() ?? '';
    var separate = false;
    final grams = await showSufraDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SufraAlertDialog(
          title: Text(
            ar ? 'زيت زيتون إضافي، اختياري' : 'Extra olive oil, optional',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ar
                      ? 'الجرامات في الجزء اللي أكلته، مش كل الحلة. زيت زيتون فقط. لو النوع أو الكمية مش معروفين تخطّى. الزيت المجهول والإضافات التانية تفضل غير محسوبة.'
                      : 'Grams in the portion you ate, not the whole pot. Olive oil only. Skip if type or amount is unknown. Unknown oil and other additions remain uncounted.',
                ),
                TextFormField(
                  initialValue: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => set(() => amount = v),
                  decoration: InputDecoration(
                    labelText: ar
                        ? 'زيت زيتون بالجرام (حتى200جم)'
                        : 'Olive oil grams (up to200g)',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: separate,
                  onChanged: (v) => set(() => separate = v ?? false),
                  title: Text(
                    ar
                        ? 'متأكد إن الزيت ده مش محسوب ضمن الأصناف المقترحة'
                        : 'This oil is not already included in the suggested foods',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ar ? 'تخطّي' : 'Skip'),
            ),
            if (_addedOil != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 0.0),
                child: Text(ar ? 'احذف الزيت المضاف' : 'Remove added oil'),
              ),
            TextButton(
              onPressed:
                  separate &&
                      (parseDecimalInput(amount) ?? 0) > 0 &&
                      (parseDecimalInput(amount) ?? 201) <= 200
                  ? () => Navigator.pop(ctx, parseDecimalInput(amount))
                  : null,
              child: Text(ar ? 'أضف للحساب' : 'Add to calculation'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || grams == null || operation != _operation) return;
    if (grams == 0) {
      setState(() => _addedOil = null);
      return;
    }
    final foods = await LocalFoodDataSource().getAll();
    if (!mounted || operation != _operation) return;
    final portion = PhotoMealClarification.oliveOil(
      grams: grams,
      separateFromFood: separate,
      meal: _chosen.values,
      foods: foods,
    );
    if (portion != null) {
      setState(() => _addedOil = portion);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SufraSnackBar(
          content: Text(
            ar
                ? 'الزيت متحسبش، ممكن يكون موجود بالفعل أو الكمية غير صالحة.'
                : 'Oil was not added. It may already be included or the amount is invalid.',
          ),
        ),
      );
    }
  }

  Future<void> _dictateNotes() async {
    if (_busy) return;
    await _device.pause();
    if (!mounted) return;
    final value = await showSufraBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DictationTextSheet(initialText: _notes.text),
    );
    if (!mounted) return;
    if (value != null) {
      setState(() {
        _notes.text = value;
      });
    }
    if (_image == null) await _device.initialize();
  }

  Future<void> _toggleFlash() async {
    final next = !_flash;
    final changed = await _device.flash(next);
    if (!mounted) return;
    if (changed) {
      setState(() {
        _flash = next;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SufraSnackBar(
          content: Text(AppLocalizations.of(context).cameraFlashUnavailable),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), image = _image;
    final ready = _device.status == CaptureStatus.ready;
    final hasThemeControl = context.watch<ThemeCubit?>() != null;
    final statusText = switch (_device.status) {
      CaptureStatus.denied => l.cameraDenied,
      CaptureStatus.restricted => l.cameraRestricted,
      CaptureStatus.unavailable => l.cameraMissing,
      CaptureStatus.failed => l.cameraFailed,
      CaptureStatus.paused => l.cameraPaused,
      _ => l.cameraStarting,
    };
    final errorText = switch (_error) {
      'size' => l.cameraTooLarge,
      'image' => l.cameraBadImage,
      'capture' => l.cameraFailed,
      'unavailable' => l.cameraAiUnavailable,
      'empty' => l.cameraEmpty,
      'invalidResponse' => l.cameraInvalidResponse,
      null => '',
      _ => l.cameraNetwork,
    };
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (image == null && hasThemeControl)
                const SizedBox(
                  height: 44,
                  child: Center(child: LiquidThemeButton(size: 32)),
                ),
              if (image == null)
                CameraModeHeader(
                  topInset: hasThemeControl ? 0 : 44,
                  onClose: () => context.pop(),
                  onVoice: () => _openCaptureMode('/voice-meal'),
                  onBarcode: () => _openCaptureMode('/barcode'),
                  onFlash: ready && !_busy ? _toggleFlash : null,
                  flashEnabled: _flash,
                )
              else
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                        tooltip: l.cameraClose,
                      ),
                      Expanded(
                        child: Text(
                          _busy
                              ? (Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'بنحلّل وجبتك'
                                    : 'Recognizing your meal')
                              : _result == null
                              ? (Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'الصورة جاهزة؟'
                                    : 'Is the photo ready?')
                              : l.cameraTitle,
                          textAlign: TextAlign.center,
                          style: context.readableDisplayStyle(size: 24),
                        ),
                      ),
                      IconButton(
                        onPressed: null,
                        icon: const Icon(Icons.photo_library_outlined),
                        tooltip: l.cameraGallery,
                      ),
                      IconButton(
                        onPressed: null,
                        icon: Icon(_flash ? Icons.flash_on : Icons.flash_off),
                        tooltip: l.cameraFlash,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _busy && image != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(image.bytes, fit: BoxFit.contain),
                          const PhotoScanOverlay(),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: SizedBox(
                              height: image == null ? 420 : 240,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(color: const Color(0x66000000)),
                                  if (image != null)
                                    Image.memory(
                                      image.bytes,
                                      fit: BoxFit.contain,
                                    )
                                  else if (ready)
                                    _device.preview()
                                  else
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(30),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_device.status ==
                                                CaptureStatus.starting)
                                              const CircularProgressIndicator()
                                            else
                                              const Icon(
                                                Icons.no_photography_outlined,
                                                size: 50,
                                                color: Color(0xFF67E8F9),
                                              ),
                                            const SizedBox(height: 18),
                                            Text(
                                              statusText,
                                              textAlign: TextAlign.center,
                                            ),
                                            if (_device.status !=
                                                CaptureStatus.starting)
                                              TextButton(
                                                onPressed: _device.initialize,
                                                child: Text(l.cameraRetry),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (image == null)
                                    const CameraViewfinderCorners(),
                                  if (image == null)
                                    Positioned(
                                      bottom: 24,
                                      left: 20,
                                      right: 20,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xCC0A1022),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: const Color(0x33FFFFFF),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              l.cameraFrameHint,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFF5F7FA),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              l.cameraLightHint,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFF5F7FA),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (_busy) const PhotoScanOverlay(),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height:
                                image == null &&
                                    MediaQuery.textScalerOf(
                                          context,
                                        ).scale(13) <=
                                        18 &&
                                    Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'ar'
                                ? (MediaQuery.sizeOf(context).height -
                                          MediaQuery.paddingOf(
                                            context,
                                          ).vertical -
                                          112 -
                                          420 -
                                          98 -
                                          80)
                                      .clamp(16.0, 220.0)
                                : 16,
                          ),
                          if (image == null)
                            CameraCaptureDock(
                              zooms: [
                                for (final z in [.5, 1.0, 2.0])
                                  if (z >= _device.minZoom &&
                                      z <= _device.maxZoom)
                                    z,
                              ],
                              zoom: _zoom,
                              onZoom: ready && !_busy
                                  ? (value) async {
                                      try {
                                        await _device.zoom(value);
                                        if (mounted) {
                                          setState(() => _zoom = value);
                                        }
                                      } catch (_) {}
                                    }
                                  : null,
                              onCapture: ready && !_busy ? _capture : null,
                              onGallery: !_busy
                                  ? () => _capture(gallery: true)
                                  : null,
                            )
                          else ...[
                            TextButton.icon(
                              onPressed: !_busy ? _retake : null,
                              icon: const Icon(Icons.replay),
                              label: Text(l.cameraRetake),
                            ),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l.cameraMealType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
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
                                          onSelected: !_busy
                                              ? (_) => setState(() {
                                                  _mealType = entry.key;
                                                })
                                              : null,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(l.cameraNotes),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < _hintLabels(l).length;
                                        i++
                                      )
                                        FilterChip(
                                          label: Text(_hintLabels(l)[i]),
                                          selected: _hints.contains(i),
                                          onSelected: !_busy
                                              ? (value) => setState(() {
                                                  value
                                                      ? _hints.add(i)
                                                      : _hints.remove(i);
                                                })
                                              : null,
                                        ),
                                    ],
                                  ),
                                  TextField(
                                    controller: _notes,
                                    enabled: !_busy,
                                    maxLength: 1000,
                                    decoration: InputDecoration(
                                      hintText: l.cameraNotesHint,
                                      suffixIcon: IconButton(
                                        tooltip: l.voiceDescription,
                                        onPressed: _busy ? null : _dictateNotes,
                                        icon: const Icon(Icons.mic_none),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    widget.provider.isAvailable
                                        ? l.cameraPrivacy
                                        : l.cameraNoUpload,
                                    style: context.mutedStyle(size: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GradientButton(
                              label: _busy
                                  ? l.cameraAnalyzing
                                  : l.cameraAnalyze,
                              onPressed: !_busy ? _analyze : null,
                            ),
                          ],
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                errorText,
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                ),
                              ),
                            ),
                          if (_result != null) ...[
                            PhotoMealResultCard(
                              result: _result!,
                              chosen: _chosen,
                              addedOil: _addedOil,
                              skipped: _skipped,
                              unconfirmed: _unconfirmed,
                              clarificationSkipped: _clarificationSkipped,
                              onSkipClarification: () =>
                                  setState(() => _clarificationSkipped = true),
                              onClarifyOil: _clarifyOil,
                              onChoose: _pickCandidate,
                              onConfirm: (i) =>
                                  setState(() => _unconfirmed.remove(i)),
                              onPortion: _editResultPortion,
                              onSkip: (i) => setState(() {
                                _chosen.remove(i);
                                _addedOil = null;
                                _unconfirmed.remove(i);
                                _skipped.add(i);
                              }),
                            ),
                            GradientButton(
                              label: widget.returnReviewedDraft
                                  ? (Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 'رجّع الاختيارات للمدرّب'
                                        : 'Use reviewed foods with Coach')
                                  : l.mealReviewTitle,
                              onPressed:
                                  _chosen.isNotEmpty &&
                                      _unconfirmed.isEmpty &&
                                      _chosen.length + _skipped.length ==
                                          _result!.items.length
                                  ? _reviewCandidates
                                  : null,
                            ),
                            for (final note in _result!.generalNotes)
                              Text(
                                localizedRecognitionNote(note, l),
                                style: context.mutedStyle(),
                              ),
                          ],
                          TextButton.icon(
                            onPressed: !_busy ? _manual : null,
                            icon: Icon(
                              _result == null
                                  ? Icons.search
                                  : Icons.add_circle_outline,
                            ),
                            label: Text(
                              _result == null
                                  ? l.cameraManual
                                  : (Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 'ضيف صنف ناقص للطبق'
                                        : 'Add a missing food to this meal'),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ConsentBody extends StatefulWidget {
  const _ConsentBody({
    required this.short,
    required this.detailsLabel,
    required this.disclosure,
    required this.policy,
  });
  final String short, detailsLabel, disclosure, policy;
  @override
  State<_ConsentBody> createState() => _ConsentBodyState();
}

class _ConsentBodyState extends State<_ConsentBody> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.short),
        TextButton(
          onPressed: () => setState(() => _open = !_open),
          child: Text(widget.detailsLabel),
        ),
        if (_open) ...[
          Text(widget.disclosure),
          const SizedBox(height: 8),
          SelectableText(widget.policy),
        ],
      ],
    ),
  );
}
