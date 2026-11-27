import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';

void main() {
  test('legacy profile merge never clears existing acceptance', () {
    const user = UserProfileModel(uid: 'u', displayName: 'n');
    expect(user.toMap().containsKey('policyAcceptance'), isFalse);
    expect(UserProfileModel.fromMap({'uid': 'u'}).policyAcceptance, isNull);
  });
  test('version, mechanism and recording timestamp survive profile reads', () {
    final evidence = <String, dynamic>{
      'termsVersion': '2',
      'privacyVersion': '2',
      'mechanism': 'owner_whatsapp_approval_recorded_by_assistant',
      'recordedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 23, 14)),
    };
    final user = UserProfileModel.fromMap({
      'uid': 'u',
      'policyAcceptance': evidence,
    });
    expect(user.toMap()['policyAcceptance'], evidence);
    expect(user.policyAcceptance!.containsKey('acceptedAt'), isFalse);
  });
}
