import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/nutrition_profile_model.dart';
import '../../../../data/models/user_profile_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../nutrition_plan/domain/nutrition_plan_service.dart';

class ProfileSetupData {
  const ProfileSetupData({
    this.gender,
    this.dateOfBirth,
    this.heightCm,
    this.currentWeightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.nutritionGoal,
  });

  final String? gender;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final String? activityLevel;
  final String? nutritionGoal;

  ProfileSetupData copyWith({
    String? gender,
    DateTime? dateOfBirth,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    bool clearHeight = false,
    bool clearCurrentWeight = false,
    bool clearTargetWeight = false,
    String? activityLevel,
    String? nutritionGoal,
  }) {
    return ProfileSetupData(
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: clearHeight ? null : heightCm ?? this.heightCm,
      currentWeightKg: clearCurrentWeight
          ? null
          : currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: clearTargetWeight
          ? null
          : targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      nutritionGoal: nutritionGoal ?? this.nutritionGoal,
    );
  }

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return gender != null;
      case 1:
        return dateOfBirth != null;
      case 2:
        return heightCm != null && heightCm! >= 120 && heightCm! <= 230;
      case 3:
        return currentWeightKg != null &&
            currentWeightKg! >= 30 &&
            currentWeightKg! <= 300;
      case 4:
        return targetWeightKg != null &&
            targetWeightKg! >= 30 &&
            targetWeightKg! <= 300;
      case 5:
        return activityLevel != null;
      case 6:
        return nutritionGoal != null;
      default:
        return false;
    }
  }
}

sealed class ProfileSetupStatus {
  const ProfileSetupStatus();
}

class SetupEditing extends ProfileSetupStatus {
  const SetupEditing();
}

class SetupSaving extends ProfileSetupStatus {
  const SetupSaving();
}

class SetupSaved extends ProfileSetupStatus {
  const SetupSaved(this.plan, {required this.uid});

  final String uid;

  final NutritionPlanResult plan;
}

class SetupFailed extends ProfileSetupStatus {
  const SetupFailed(this.message);

  final String message;
}

class ProfileSetupState {
  const ProfileSetupState({
    this.step = 0,
    this.data = const ProfileSetupData(),
    this.status = const SetupEditing(),
  });

  static const int totalSteps = 7;

  final int step;
  final ProfileSetupData data;
  final ProfileSetupStatus status;

  ProfileSetupState copyWith({
    int? step,
    ProfileSetupData? data,
    ProfileSetupStatus? status,
  }) {
    return ProfileSetupState(
      step: step ?? this.step,
      data: data ?? this.data,
      status: status ?? this.status,
    );
  }
}

/// Seven-step personal setup wizard. Entered data survives back/forward
/// navigation because it lives in this cubit, not in the step widgets.
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit({
    required NutritionRepository nutritionRepository,
    required UserRepository userRepository,
    NutritionPlanService planService = const NutritionPlanService(),
    String? Function()? currentUid,
  }) : _nutritionRepository = nutritionRepository,
       _userRepository = userRepository,
       _planService = planService,
       _currentUid = currentUid,
       super(const ProfileSetupState());

  final NutritionRepository _nutritionRepository;
  final UserRepository _userRepository;
  final NutritionPlanService _planService;
  final String? Function()? _currentUid;
  int _generation = 0;
  String? _owner;
  bool _saving = false;

  void ownerChanged(String? uid) {
    if (_owner == uid) return;
    _owner = uid;
    _generation++;
    _saving = false;
    if (!isClosed) emit(const ProfileSetupState());
  }

  void update(ProfileSetupData data) {
    if (_saving || isClosed) return;
    emit(state.copyWith(data: data));
  }

  bool get canAdvance => state.data.isStepValid(state.step);

  void next() {
    if (_saving || isClosed || !canAdvance) return;
    if (state.step < ProfileSetupState.totalSteps - 1) {
      emit(state.copyWith(step: state.step + 1));
    }
  }

  void back() {
    if (_saving || isClosed) return;
    if (state.step > 0) {
      emit(state.copyWith(step: state.step - 1));
    }
  }

  /// Computes the plan and persists the profile through the existing
  /// Firestore data flow.
  Future<NutritionPlanResult?> finish(String uid) async {
    if (_saving ||
        isClosed ||
        !canAdvance ||
        (_currentUid != null && _currentUid() != uid)) {
      return null;
    }
    _saving = true;
    final generation = _generation;
    bool active() =>
        !isClosed &&
        generation == _generation &&
        (_currentUid == null || _currentUid() == uid);
    emit(state.copyWith(status: const SetupSaving()));
    try {
      final data = state.data;
      final plan = _planService.compute(
        NutritionPlanInput(
          gender: data.gender!,
          dateOfBirth: data.dateOfBirth!,
          heightCm: data.heightCm!,
          currentWeightKg: data.currentWeightKg!,
          targetWeightKg: data.targetWeightKg!,
          activityLevel: data.activityLevel!,
          nutritionGoal: data.nutritionGoal!,
        ),
      );

      final profile = NutritionProfileModel(
        profileId: 'primary',
        gender: data.gender!,
        dateOfBirth: data.dateOfBirth!,
        heightCm: data.heightCm!,
        currentWeightKg: data.currentWeightKg!,
        targetWeightKg: data.targetWeightKg!,
        activityLevel: data.activityLevel!,
        nutritionGoal: data.nutritionGoal!,
        dailyCalorieTarget: plan.dailyCalories,
        proteinTarget: plan.proteinGrams,
        carbsTarget: plan.carbsGrams,
        fatTarget: plan.fatGrams,
      );
      await _nutritionRepository.saveNutritionProfile(uid, profile);

      if (!active()) return null;
      final user = await _userRepository.getCurrentUser();
      if (!active()) return null;
      if (user != null && user.uid != uid) {
        throw StateError('Setup owner changed');
      }
      if (user != null) {
        await _userRepository.upsertUser(
          UserProfileModel(
            uid: user.uid,
            displayName: user.displayName,
            email: user.email,
            phoneNumber: user.phoneNumber,
            photoUrl: user.photoUrl,
            preferredLanguage: user.preferredLanguage,
            timezone: user.timezone,
            measurementSystem: user.measurementSystem,
            notificationPreferences: user.notificationPreferences,
            onboardingCompleted: true,
            accountStatus: user.accountStatus,
            createdAt: user.createdAt,
          ),
        );
      }

      if (!active()) return null;
      emit(state.copyWith(status: SetupSaved(plan, uid: uid)));
      return plan;
    } catch (error) {
      if (active()) emit(state.copyWith(status: SetupFailed(error.toString())));
      return null;
    } finally {
      if (generation == _generation) _saving = false;
    }
  }
}
