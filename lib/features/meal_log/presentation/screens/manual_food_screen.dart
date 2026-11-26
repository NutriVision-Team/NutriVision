import '../../../../core/widgets/nebula_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/utils/operation_id.dart';
import '../../../../data/models/food_catalog_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/food_portion.dart';
import 'food_detail_screen.dart';

class ManualFoodScreen extends StatefulWidget {
  const ManualFoodScreen({super.key, this.selectOnly = false});
  final bool selectOnly;
  @override
  State<ManualFoodScreen> createState() => _ManualFoodScreenState();
}

class _ManualFoodScreenState extends State<ManualFoodScreen> {
  final _name = TextEditingController(), _source = TextEditingController();
  final _values = {
    for (final k in FoodPortion.nutrients) k: TextEditingController(),
  };
  bool _confirmed = false, _invalid = false;
  @override
  void dispose() {
    _name.dispose();
    _source.dispose();
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  void submit() {
    final parsed = <String, double?>{};
    for (final e in _values.entries) {
      final v = e.value.text.trim();
      final n = v.isEmpty ? null : parseDecimalInput(v);
      if (v.isNotEmpty && (n == null || n < 0 || n > 100000)) {
        setState(() => _invalid = true);
        return;
      }
      parsed[e.key] = n;
    }
    if (!_confirmed ||
        _name.text.trim().isEmpty ||
        _source.text.trim().isEmpty ||
        parsed['calories'] == null) {
      setState(() => _invalid = true);
      return;
    }
    final food = FoodCatalogModel(
      foodId: newOperationId('manual'),
      name: _name.text.trim(),
      source: 'user_entered: ${_source.text.trim()}',
      verificationStatus: 'user_entered_unverified',
      nutritionPer100g: parsed,
    );
    if (widget.selectOnly) {
      Navigator.of(context).pop(food);
    } else {
      context.push(FoodDetailScreen.routePath, extra: food);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.foodManualTitle)),
      body: NebulaBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.foodManualNote),
            TextField(
              controller: _name,
              maxLength: 120,
              decoration: InputDecoration(labelText: l.mealName),
            ),
            Text(l.foodManualSource),
            TextField(
              controller: _source,
              maxLength: 200,
              decoration: InputDecoration(hintText: l.foodManualRequired),
            ),
            for (final e in _values.entries) ...[
              const SizedBox(height: 12),
              Text('${nutrientLabel(l, e.key)} / 100 ${l.foodGramUnit}'),
              TextField(
                controller: e.value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: e.key == 'calories'
                      ? l.foodManualRequired
                      : l.foodUnknown,
                ),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _confirmed = !_confirmed),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.foodManualConfirm),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Checkbox(
                        value: _confirmed,
                        onChanged: (v) =>
                            setState(() => _confirmed = v ?? false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_invalid)
              Text(
                l.foodManualInvalid,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(onPressed: submit, child: Text(l.mealReviewTitle)),
          ],
        ),
      ),
    );
  }
}
