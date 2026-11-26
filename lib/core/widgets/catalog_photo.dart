import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Licensed photos and explicitly disclosed generated illustrations.
class CatalogPhoto extends StatelessWidget {
  const CatalogPhoto({super.key, required this.name, required this.size});
  final String name;
  final double size;
  static const bindings = <String, String>{
    '2646170': 'chicken-breast-raw',
    '328637': 'cheddar',
    '2684442': 'tilapia-raw',
    '1105314': 'banana',
    '2258586': 'carrot',
    '746768': 'dried-fig',
    '747447': 'broccoli',
    '2685577': 'eggplant',
    '2710824': 'avocado',
    '1999632': 'spinach',
  };
  static const generatedIds = <String>{
    '168878',
    '168928',
    '172421',
    '173757',
    '171413',
    '173753',

    '748967',
    '747997',
    '748236',
    '746782',
    '746778',
    '746776',
    '2259793',
    '2647437',
    '330137',
    '2259794',
    '2259796',
    '328841',
    '789828',
    '790508',
    '331960',
    '2646171',
    '2727566',
    '2514747',
    '2514743',
    '2514744',
    '2727574',
    '2727573',
    '2727570',
    '2684441',
    '2684440',
    '334194',
    '2684445',
    '2684443',
    '2512381',
    '2512380',
    '2710820',
    '2346396',
    '790018',
    '790085',
    '2003589',
    '2758998',
    '2759000',
    '2758993',
    '2758994',
    '2644283',
    '2644282',
    '2644288',
    '2644289',
    '747441',
    '321358',
    '2515376',
    '2758989',
    '1999634',
    '790646',
    '790577',
    '1104647',
    '2346401',
    '2346404',
    '2346406',
    '2685568',
    '2258588',
    '2258590',
    '2685573',
    '2346407',
    '746769',
    '2346400',
    '2644291',
    '1999629',
    '323505',
    '2685580',
    '1750341',
    '746771',
    '2346413',
    '2346409',
    '2710833',
    '2747675',
    '2758980',
    '2710832',
    '746770',
    '2346393',
    '2346394',
    '2515375',
    '2515379',
    '2515374',
    '2515381',
    '2262073',
    '746784',
    '746775',
    '747693',
    '1999630',
  };
  static bool isGenerated(String id) =>
      generatedIds.contains(id.split('_').last) ||
      bindings.containsKey(id.split('_').last);
  static String? forFood(String id) =>
      bindings[id.split('_').last] ??
      (isGenerated(id) ? id.split('_').last : null);
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/${generatedIds.contains(name) ? 'generated_food' : 'catalog_photos'}/$name.png',
    width: size,
    height: size,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
    fit: BoxFit.contain,
  );
}

class CatalogImageCredit extends StatelessWidget {
  const CatalogImageCredit({super.key, required this.foodId});
  final String foodId;
  @override
  Widget build(BuildContext context) {
    final name = CatalogPhoto.forFood(foodId);
    if (name == null) return const SizedBox.shrink();
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return TextButton(
      onPressed: () async {
        if (CatalogPhoto.isGenerated(foodId)) {
          await showSufraDialog<void>(
            context: context,
            builder: (c) => SufraAlertDialog(
              title: Text(ar ? 'رسم توضيحي مولّد' : 'Generated illustration'),
              content: Text(
                ar
                    ? 'الصورة رسم توضيحي فقط. ليست صورة حقيقية أو قياسًا للكمية أو نوع المنتج أو نسبة الدهون. القيم الغذائية من مصدر البيانات المكتوب، وليست مستنتجة من الصورة.'
                    : 'Illustration only, not a photograph, portion measurement, product identification or fat assay. Nutrition comes from the cited data source, not the image.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(ar ? 'إغلاق' : 'Close'),
                ),
              ],
            ),
          );
          return;
        }
        final data =
            (jsonDecode(
                      await rootBundle.loadString(
                        'assets/data/image_credits.json',
                      ),
                    )
                    as List)
                .cast<Map<String, dynamic>>();
        final credit = data.firstWhere((i) => i['id'] == name);
        if (!context.mounted) return;
        await showSufraDialog<void>(
          context: context,
          builder: (c) => SufraAlertDialog(
            title: Text(ar ? 'مصدر الصورة' : 'Image credit'),
            content: SingleChildScrollView(
              child: SelectableText(
                '${credit['author']}\n${credit['license']}\n${credit['source']}\n${credit['licenseUrl']}\n${credit['changes']}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(ar ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        );
      },
      child: Text(
        CatalogPhoto.isGenerated(foodId)
            ? (ar ? 'عن الصورة' : 'About this image')
            : (ar ? 'مصدر الصورة وترخيصها' : 'Image source and license'),
      ),
    );
  }
}
