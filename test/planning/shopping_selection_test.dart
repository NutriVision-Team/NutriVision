import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/shopping/presentation/cubit/shopping_cubit.dart';
import 'package:sufradepi/features/shopping/data/shopping_repository.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'support/planning_memory_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'selected catalog identity persists and changes image binding without duplicate rows',
    () async {
      final repository = FirestoreShoppingRepository(PlanningMemoryFirestore());
      final c = ShoppingCubit(
        userId: 'u',
        currentUid: () => 'u',
        repository: repository,
        foods: LocalFoodDataSource(),
      );
      await c.load();
      final all = await c.catalogChoices();
      final carrot = all.firstWhere((f) => f.id.endsWith('2258586'));
      final banana = all.firstWhere((f) => f.id.endsWith('1105314'));
      expect(await c.selectCatalogFood(carrot), true);
      final id = c.state.items.single.itemId;
      expect(c.state.items.single.linkedFoodId, carrot.id);
      await c.toggle(id);
      expect(c.state.items.single.isPurchased, true);
      expect(await c.selectCatalogFood(banana, replaceItemId: id), true);
      expect(c.state.items.single.linkedFoodId, banana.id);
      expect(c.state.items.single.isPurchased, false);
      await c.load();
      expect(c.state.items.single.linkedFoodId, banana.id);
      await c.close();
    },
  );
}
