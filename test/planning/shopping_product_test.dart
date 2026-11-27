import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/barcode/domain/off_product.dart';
import 'package:sufradepi/features/shopping/presentation/cubit/shopping_cubit.dart';
import 'package:sufradepi/features/shopping/data/shopping_repository.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'support/planning_memory_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const first = OffProduct(
    barcode: '3017620422003',
    name: 'Synthetic spread',
    brand: 'Fixture brand',
    imageUrl: 'https://example.test/pack-a.jpg',
    sourceUrl: 'https://example.test/product-a',
  );
  const second = OffProduct(
    barcode: '5449000000996',
    name: 'Synthetic liquid pack',
    imageUrl: 'https://example.test/pack-b.jpg',
    basis: NutrientBasis.per100ml,
  );
  test(
    'selected exact pack survives reload, toggle and replacement without generic image identity',
    () async {
      final db = PlanningMemoryFirestore();
      final repo = FirestoreShoppingRepository(db);
      final c = ShoppingCubit(
        userId: 'u',
        currentUid: () => 'u',
        repository: repo,
        foods: LocalFoodDataSource(),
      );
      await c.load();
      expect(await c.selectProduct(first), true);
      final id = c.state.items.single.itemId;
      expect(c.state.items.single.linkedFoodId, isNull);
      expect(c.state.items.single.unit, 'pack');
      expect(c.state.items.single.quantity, 1);
      await c.toggle(id);
      expect(c.state.items.single.productBarcode, first.barcode);
      await c.close();
      final restarted = ShoppingCubit(
        userId: 'u',
        currentUid: () => 'u',
        repository: FirestoreShoppingRepository(db),
        foods: LocalFoodDataSource(),
      );
      await restarted.load();
      expect(restarted.state.items.single.productImageUrl, first.imageUrl);
      expect(restarted.state.items.single.productBrand, first.brand);
      expect(restarted.state.items.single.isPurchased, true);
      expect(await restarted.selectProduct(second, replaceItemId: id), true);
      expect(restarted.state.items, hasLength(1));
      expect(restarted.state.items.single.itemId, id);
      expect(restarted.state.items.single.productImageUrl, second.imageUrl);
      expect(restarted.state.items.single.isPurchased, false);
      final carrot = (await restarted.catalogChoices()).firstWhere(
        (f) => f.id.endsWith('2258586'),
      );
      expect(
        await restarted.selectCatalogFood(carrot, replaceItemId: id),
        true,
      );
      expect(restarted.state.items.single.productBarcode, isNull);
      expect(restarted.state.items.single.productImageUrl, isNull);
      await restarted.close();
    },
  );
  test('invalid code/count and stale account do not write product', () async {
    final db = PlanningMemoryFirestore();
    var owner = 'u';
    final c = ShoppingCubit(
      userId: 'u',
      currentUid: () => owner,
      repository: FirestoreShoppingRepository(db),
      foods: LocalFoodDataSource(),
    );
    await c.load();
    expect(
      await c.selectProduct(const OffProduct(barcode: 'invalid', name: 'Bad')),
      false,
    );
    expect(await c.selectProduct(first, packs: 0), false);
    expect(db.documents, isEmpty);
    owner = 'other';
    await expectLater(c.selectProduct(first), throwsStateError);
    expect(db.documents, isEmpty);
    await c.close();
  });
}
