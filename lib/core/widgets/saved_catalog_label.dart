import 'package:flutter/material.dart';
import '../../data/models/meal_entry_model.dart';
import '../../features/food_catalog/data/local_food_repository.dart';
import '../../l10n/app_localizations.dart';

/// Localizes a stored system catalog label, never a user-edited label.
class SavedCatalogLabel extends StatefulWidget {
  const SavedCatalogLabel({
    super.key,
    required this.item,
    this.style,
    this.amount = false,
  });
  final MealItemModel item;
  final TextStyle? style;
  final bool amount;
  @override
  State<SavedCatalogLabel> createState() => _SavedCatalogLabelState();
}

class _SavedCatalogLabelState extends State<SavedCatalogLabel> {
  final repository = LocalFoodRepository();
  late var food = repository.getFoodById(widget.item.foodId);
  @override
  void didUpdateWidget(covariant SavedCatalogLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.foodId != widget.item.foodId) {
      food = repository.getFoodById(widget.item.foodId);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: food,
    builder: (context, snapshot) {
      final record = snapshot.data;
      final item = widget.item;
      final label = record != null && item.foodName == record.name
          ? (record.localizedNames?[Localizations.localeOf(
                      context,
                    ).languageCode]
                    as String? ??
                record.name)
          : item.foodName;
      if (!widget.amount) return Text(label, style: widget.style);
      return Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: widget.style),
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              Text(item.weightInGrams.toStringAsFixed(1), style: widget.style),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).foodGramUnit,
                style: widget.style,
              ),
            ],
          ),
        ],
      );
    },
  );
}
