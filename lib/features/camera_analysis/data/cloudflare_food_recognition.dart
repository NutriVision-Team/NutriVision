import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../domain/food_recognition_provider.dart';

/// Short-lived signed qualification capability is set in session memory only.
/// Never placed in environment defines, source, preferences, URLs, or logs.
class FoodVisionQualification {
  static String? bearer;
  static String? fixtureHash;
}

class CloudflareFoodRecognitionProvider
    implements
        NonpersonalQualificationProvider,
        LocalizedRecognitionDisclosure {
  CloudflareFoodRecognitionProvider({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static final endpoint = Uri.parse(
    'https://sufra-food-vision.moos456456.workers.dev/recognize',
  );
  @override
  bool get isAvailable =>
      FoodVisionQualification.bearer != null &&
      FoodVisionQualification.fixtureHash != null;
  @override
  bool permitsImage(List<int> bytes) =>
      isAvailable &&
      sha256.convert(bytes).toString() == FoodVisionQualification.fixtureHash;
  @override
  String get providerName => 'Cloudflare Workers AI';
  @override
  Uri get privacyPolicy => Uri.parse(
    'https://developers.cloudflare.com/workers-ai/platform/data-usage/',
  );
  @override
  String get processingDisclosure =>
      'Nonpersonal test only. This exact approved test frame is processed by Cloudflare Workers AI. No notes, meal type, identity, health profile or nutrition data are sent. The image is not saved by this app backend. Results are candidate names only and require review. Personal uploads remain disabled.';
  @override
  String disclosureFor(String languageCode) => languageCode == 'ar'
      ? 'اختبار بصورة غير شخصية فقط. هتتبعت الصورة التجريبية المحددة دي لـCloudflare Workers AI. مش هنبعت الملاحظات أو نوع الوجبة أو الهوية أو الملف الصحي. خادم التطبيق مش بيحفظ الصورة. النتيجة أسماء أكل مقترحة للمراجعة، مش قياس وزن أو حساب سعرات. إرسال الصور الشخصية لسه مقفول.'
      : processingDisclosure;
  @override
  Future<FoodRecognitionResult> recognize(FoodRecognitionInput input) async {
    if (!permitsImage(input.jpegBytes)) {
      throw const FoodRecognitionException(RecognitionFailure.unavailable);
    }
    // Normal Firebase-token route is fail-closed on the server unless UID is explicitly allowlisted.
    final token =
        FoodVisionQualification.bearer ??
        await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const FoodRecognitionException(RecognitionFailure.unavailable);
    }
    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'image/jpeg',
            },
            body: input.jpegBytes,
          )
          .timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        throw const FoodRecognitionException(RecognitionFailure.unavailable);
      }
      return FoodRecognitionResult.parse(response.body, catalogIds: const {});
    } on FoodRecognitionException {
      rethrow;
    } on FormatException {
      throw const FoodRecognitionException(RecognitionFailure.invalidResponse);
    } catch (_) {
      throw const FoodRecognitionException(RecognitionFailure.network);
    }
  }
}
