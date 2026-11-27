import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../core/utils/date_utils.dart';
import 'package:clock/clock.dart' as time;
import '../../../barcode/domain/off_product.dart';
import '../../../barcode/domain/barcode_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/meal_plan_model.dart';
import '../../../../data/models/shopping_list_model.dart';
import '../../../food_catalog/data/datasources/local_food_data_source.dart';
import '../../data/shopping_repository.dart';
import '../../domain/shopping_list_logic.dart';

@immutable
class ShoppingState {
  const ShoppingState({
    required this.status,
    this.list,
    this.items = const [],
    this.busy = false,
    this.generatedFromPlan = false,
    this.skippedCount = 0,
  });

  final ShoppingStatus status;
  final ShoppingListModel? list;
  final List<ShoppingListItemModel> items;
  final bool busy;

  /// True when the visible items were generated from the saved weekly plan.
  final bool generatedFromPlan;

  /// Plan entries that had no measured quantity or resolvable food, so the
  /// UI can disclose them instead of hiding the gap.
  final int skippedCount;

  (int, int) get progress => shoppingProgress(items);

  ShoppingState copyWith({
    ShoppingStatus? status,
    ShoppingListModel? list,
    List<ShoppingListItemModel>? items,
    bool? busy,
    bool? generatedFromPlan,
    int? skippedCount,
  }) => ShoppingState(
    status: status ?? this.status,
    list: list ?? this.list,
    items: items ?? this.items,
    busy: busy ?? this.busy,
    generatedFromPlan: generatedFromPlan ?? this.generatedFromPlan,
    skippedCount: skippedCount ?? this.skippedCount,
  );
}

enum ShoppingStatus { loading, ready, error }

class ShoppingCubit extends Cubit<ShoppingState> {
  ShoppingCubit({
    required this.userId,
    this.currentUid,
    this.nutrition,
    required this.repository,
    required this.foods,
  }) : super(const ShoppingState(status: ShoppingStatus.loading));

  final NutritionRepository? nutrition;
  final String userId;
  final String? Function()? currentUid;
  bool get inactive =>
      isClosed ||
      userId.isEmpty ||
      (currentUid != null && currentUid!() != userId);
  void assertActive() {
    if (inactive) throw StateError('Account no longer active');
  }

  @override
  void emit(ShoppingState state) {
    if (!inactive) super.emit(state);
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }

  final ShoppingRepository repository;
  final LocalFoodDataSource foods;

  static const listId = FirestoreShoppingRepository.currentListId;

  int _generation = 0;

  Future<void> load() async {
    assertActive();
    final myGeneration = ++_generation;
    emit(state.copyWith(status: ShoppingStatus.loading));
    try {
      if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
      final list = await repository.getList(userId, listId);
      final items = list == null
          ? <ShoppingListItemModel>[]
          : await repository.getItems(userId, list.listId);
      if (inactive || myGeneration != _generation) return;
      emit(
        ShoppingState(
          status: ShoppingStatus.ready,
          list: list,
          items: items,
          generatedFromPlan: list?.planId != null,
        ),
      );
    } catch (_) {
      if (inactive || myGeneration != _generation) return;
      emit(const ShoppingState(status: ShoppingStatus.error));
    }
  }

  /// Checkbox toggles update visible progress immediately and persist the
  /// actual state; a failed write rolls the checkbox back.
  Future<void> toggle(String itemId) async {
    assertActive();
    final index = state.items.indexWhere((item) => item.itemId == itemId);
    if (state.busy || index < 0 || state.list == null) return;
    final current = state.items[index];
    final updated = ShoppingListItemModel(
      itemId: current.itemId,
      name: current.name,
      quantity: current.quantity,
      unit: current.unit,
      category: current.category,
      isPurchased: !current.isPurchased,
      linkedFoodId: current.linkedFoodId,
      productBarcode: current.productBarcode,
      productImageUrl: current.productImageUrl,
      productBrand: current.productBrand,
      productSourceUrl: current.productSourceUrl,
    );
    final items = [...state.items];
    items[index] = updated;
    emit(state.copyWith(items: items, busy: true));
    try {
      assertActive();
      await repository.setPurchased(
        userId,
        state.list!.listId,
        itemId,
        updated.isPurchased,
      );
      emit(state.copyWith(busy: false));
    } catch (_) {
      final rolledBack = [...state.items];
      final rollbackIndex = rolledBack.indexWhere((i) => i.itemId == itemId);
      if (rollbackIndex >= 0) {
        rolledBack[rollbackIndex] = current;
        emit(state.copyWith(items: rolledBack, busy: false));
      }
    }
  }

  Future<bool> _ensureList() async {
    if (state.list != null) return true;
    try {
      assertActive();
      final list = await repository.saveList(
        userId,
        const ShoppingListModel(
          listId: listId,
          title: 'Shopping',
          planId: null,
          status: 'active',
        ),
      );
      assertActive();
      emit(state.copyWith(list: list));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<LocalFoodRecord>> catalogChoices() => foods.getAll();

  Future<bool> selectCatalogFood(
    LocalFoodRecord food, {
    String? replaceItemId,
    double? grams,
  }) async {
    assertActive();
    if (grams != null && (!grams.isFinite || grams <= 0 || grams > 10000)) {
      return false;
    }
    if (state.busy || !await _ensureList()) return false;
    final index = state.items.indexWhere((i) => i.itemId == replaceItemId);
    final old = index < 0 ? null : state.items[index];
    final item = ShoppingListItemModel(
      itemId:
          old?.itemId ?? 'selected_${DateTime.now().microsecondsSinceEpoch}',
      name: food.nameAr.isEmpty ? food.nameEn : food.nameAr,
      quantity: grams ?? old?.quantity ?? 250,
      unit: grams != null ? 'g' : old?.unit ?? 'g',
      category: shoppingGroupFor(food.category).name,
      isPurchased: false,
      linkedFoodId: food.id,
    );
    emit(state.copyWith(busy: true));
    try {
      await repository.upsertItem(userId, state.list!.listId, item);
      assertActive();
      final values = [...state.items];
      if (index < 0) {
        values.add(item);
      } else {
        values[index] = item;
      }
      emit(state.copyWith(items: values, busy: false));
      return true;
    } catch (_) {
      emit(state.copyWith(busy: false));
      return false;
    }
  }

  /// Fresh account/day snapshot. No shopping quantities are logged as consumed.
  Future<double?> remainingToday() async {
    final repo = nutrition;
    if (repo == null || inactive) return null;
    final key = SufraDateUtils.toDateKey(time.clock.now());
    try {
      final profiles = await repo.getNutritionProfiles(userId);
      final meals = await repo.getMealEntries(userId, dateKey: key);
      final log = await repo.getDailyLog(userId, key);
      assertActive();
      if (key != SufraDateUtils.toDateKey(time.clock.now()) ||
          meals.any((m) => m.userId != userId || m.dateKey != key) ||
          (log != null && log.dateKey != key)) {
        return null;
      }
      final profile = profiles.where((p) => p.isActive).firstOrNull;
      final target = profile?.dailyCalorieTarget;
      if (target == null || !target.isFinite || target <= 0) return null;
      final confirmed = meals
          .where((m) => m.analysisStatus == 'confirmed')
          .toList();
      final consumed = confirmed.isNotEmpty
          ? confirmed.fold<double>(0, (sum, m) => sum + m.totalCalories)
          : (log?.totalCalories ?? (log == null ? 0 : double.nan));
      if (!consumed.isFinite || consumed < 0) return null;
      return target - consumed;
    } catch (_) {
      return null;
    }
  }

  /// Explicit pack selection. Pack count is not grams or a meal portion.
  Future<bool> selectProduct(
    OffProduct product, {
    String? replaceItemId,
    int packs = 1,
  }) async {
    assertActive();
    if (state.busy ||
        packs < 1 ||
        packs > 99 ||
        product.name.trim().isEmpty ||
        !BarcodeCode.hasValidLengthAndCheckDigit(product.barcode)) {
      return false;
    }
    if (!await _ensureList()) return false;
    final index = state.items.indexWhere((i) => i.itemId == replaceItemId);
    final item = ShoppingListItemModel(
      itemId: index < 0
          ? 'product_${DateTime.now().microsecondsSinceEpoch}'
          : state.items[index].itemId,
      name: product.name,
      quantity: packs.toDouble(),
      unit: 'pack',
      category: ShoppingGroup.other.name,
      isPurchased: false,
      productBarcode: product.barcode,
      productBrand: product.brand,
      productImageUrl: _safeUrl(product.imageUrl),
      productSourceUrl: _safeUrl(product.sourceUrl),
    );
    emit(state.copyWith(busy: true));
    try {
      assertActive();
      await repository.upsertItem(userId, state.list!.listId, item);
      assertActive();
      final items = [...state.items];
      if (index < 0) {
        items.add(item);
      } else {
        items[index] = item;
      }
      emit(state.copyWith(items: items, busy: false));
      return true;
    } catch (_) {
      emit(state.copyWith(busy: false));
      return false;
    }
  }

  static String? _safeUrl(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? value
        : null;
  }

  Future<bool> addManualItem(String name, double quantity, String unit) async {
    assertActive();
    final trimmed = name.trim();
    if (state.busy ||
        trimmed.isEmpty ||
        trimmed.length > 160 ||
        !quantity.isFinite ||
        quantity <= 0) {
      return false;
    }
    if (!await _ensureList()) return false;
    final item = ShoppingListItemModel(
      itemId: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      quantity: quantity,
      unit: unit.trim().isEmpty ? 'g' : unit.trim(),
      category: ShoppingGroup.other.name,
      isPurchased: false,
    );
    emit(state.copyWith(busy: true));
    try {
      assertActive();
      await repository.upsertItem(userId, state.list!.listId, item);
      emit(state.copyWith(items: [...state.items, item], busy: false));
      return true;
    } catch (_) {
      emit(state.copyWith(busy: false));
      return false;
    }
  }

  Future<void> removeItem(String itemId) async {
    assertActive();
    final list = state.list;
    if (state.busy || list == null) return;
    final before = state.items;
    emit(
      state.copyWith(
        items: before.where((item) => item.itemId != itemId).toList(),
        busy: true,
      ),
    );
    try {
      assertActive();
      await repository.removeItem(userId, list.listId, itemId);
      emit(state.copyWith(busy: false));
    } catch (_) {
      emit(state.copyWith(items: before, busy: false));
    }
  }

  /// Generates items from the saved weekly plan's measured quantities and
  /// persists them, linking the list to that plan.
  Future<bool> generateFromPlan(MealPlanModel plan) async {
    assertActive();
    if (state.busy) return false;
    final myGeneration = _generation;
    emit(state.copyWith(busy: true));
    try {
      final records = await foods.getAll();
      final byId = {for (final record in records) record.id: record};
      final aggregation = aggregatePlanItems(plan, byId);
      final list = ShoppingListModel(
        listId: listId,
        title: plan.title,
        planId: plan.planId,
        status: 'active',
      );
      assertActive();
      await repository.saveList(userId, list);
      assertActive();
      await repository.replaceGeneratedItems(
        userId,
        list.listId,
        aggregation.items,
      );
      assertActive();
      final saved = await repository.getItems(userId, list.listId);
      if (inactive || myGeneration != _generation) return false;
      emit(
        state.copyWith(
          list: list,
          items: saved,
          busy: false,
          generatedFromPlan: true,
          skippedCount: aggregation.skipped,
        ),
      );
      return true;
    } catch (_) {
      if (inactive || myGeneration != _generation) return false;
      emit(state.copyWith(busy: false));
      return false;
    }
  }

  /// Creates the empty list document on first use so manual additions have
  /// a real parent before they are written.
  Future<void> ensureList() async {
    assertActive();
    if (state.list != null) return;
    const list = ShoppingListModel(
      listId: listId,
      title: listId,
      planId: null,
      status: 'active',
    );
    await repository.saveList(userId, list);
    emit(state.copyWith(list: list));
  }
}
