import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../domain/food_recognition_provider.dart';
import 'cloudflare_food_recognition.dart';

class CloudflarePersonalFoodRecognitionProvider
    implements
        ConsentGatedFoodRecognitionProvider,
        LocalizedRecognitionDisclosure {
  CloudflarePersonalFoodRecognitionProvider({
    this.enabled = false,
    this.allowedUid = '',
    String? Function()? currentUid,
    Future<String?> Function()? idToken,
    http.Client? client,
  }) : _uid = currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _token =
           idToken ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken()),
       _client = client ?? http.Client();
  final bool enabled;
  final String allowedUid;
  final String? Function() _uid;
  final Future<String?> Function() _token;
  final http.Client _client;
  bool _busy = false;
  @override
  bool get isAvailable {
    final uid = _uid();
    if (!enabled || uid == null || uid.isEmpty) return false;
    // allowedUid is an optional restriction; empty means every signed-in user.
    return allowedUid.isEmpty || uid == allowedUid;
  }
  @override
  bool get acceptsPersonalImages => isAvailable;
  @override
  String get providerName => 'Cloudflare Workers AI';
  @override
  Uri get privacyPolicy => Uri.parse(
    'https://developers.cloudflare.com/workers-ai/platform/data-usage/',
  );
  @override
  String get processingDisclosure =>
      'After your one-image permission, the selected JPEG and Firebase sign-in token go to the Sufra server on Cloudflare. The token may include your UID, email, name and sign-in claims. Only the image and fixed food-name instructions go to the AI model, not your nutrition profile or meal notes. Visible private information in the image is included. This backend does not store images or log their contents or tokens. Cloudflare does not use inputs or outputs to train models; operational, legal and security processing may apply under its policy. Review foods and weighed quantities before saving. No measured weight or verified calories come from the image. Free-limit or service failures return manual entry without a paid upgrade.';
  @override
  String disclosureFor(String languageCode) => languageCode == 'ar'
      ? 'بعد موافقتك على الصورة دي بس، نسخة JPEG ورمز دخول Firebase هيتبعتوا لخادم سفرة على Cloudflare. الرمز ممكن يحتوي معرّف حسابك وبريدك واسمك وبيانات تسجيل الدخول. نموذج التحليل بيوصله الصورة وتعليمات ثابتة لأسماء الأكل بس، مش ملفك الغذائي أو ملاحظات الوجبة. أي بيانات خاصة ظاهرة في الصورة هتبقى ضمن الإرسال. خادم سفرة مش بيحفظ الصور ولا بيسجل محتواها أو الرمز. Cloudflare مش بتستخدم المدخلات أو المخرجات لتدريب النماذج، مع معالجة تشغيلية وقانونية وأمنية حسب سياستها. راجع الأصناف والكميات الموزونة قبل الحفظ. الصورة مش قياس للوزن أو سعرات مؤكدة. لو الحد المجاني خلص أو الخدمة تعطلت، استخدم الإدخال اليدوي من غير ترقية مدفوعة.'
      : processingDisclosure;
  @override
  Future<FoodRecognitionResult> recognize(FoodRecognitionInput input) async {
    if (!isAvailable ||
        _busy ||
        input.jpegBytes.length > 512 * 1024 ||
        input.jpegBytes.length < 4 ||
        input.jpegBytes[0] != 255 ||
        input.jpegBytes[1] != 216 ||
        input.jpegBytes[input.jpegBytes.length - 2] != 255 ||
        input.jpegBytes.last != 217) {
      throw const FoodRecognitionException(RecognitionFailure.unavailable);
    }
    _busy = true;
    try {
      final token = await _token();
      if (token == null || token.isEmpty || !isAvailable) {
        throw const FoodRecognitionException(RecognitionFailure.unavailable);
      }
      final response = await _client
          .post(
            CloudflareFoodRecognitionProvider.endpoint,
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'image/jpeg',
            },
            body: input.jpegBytes,
          )
          .timeout(const Duration(seconds: 45));
      if (!isAvailable || response.statusCode != 200) {
        throw const FoodRecognitionException(RecognitionFailure.unavailable);
      }
      return FoodRecognitionResult.parse(response.body, catalogIds: const {});
    } on FoodRecognitionException {
      rethrow;
    } on FormatException {
      throw const FoodRecognitionException(RecognitionFailure.invalidResponse);
    } catch (_) {
      throw const FoodRecognitionException(RecognitionFailure.network);
    } finally {
      _busy = false;
    }
  }
}
