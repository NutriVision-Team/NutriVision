import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Legal notices live apart from meal decisions and nutrition guidance.
class SufraLicensesScreen extends StatelessWidget {
  const SufraLicensesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'التراخيص'
            : 'Licenses',
      ),
    ),
    body: FutureBuilder<List<String>>(
      future: Future.wait([
        rootBundle.loadString('assets/data/image_credits.json'),
        rootBundle.loadString('assets/data/recipes.json'),
      ]),
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SelectableText(
            'Open Food Facts contributors\nhttps://openfoodfacts.org\nDatabase: Open Database License (ODbL). Individual contents: Database Contents License. Product images: Creative Commons Attribution ShareAlike.\nhttps://world.openfoodfacts.org/terms-of-use',
          ),
          const SizedBox(height: 20),
          const SelectableText(
            'TheMealDB\nhttps://www.themealdb.com/api.php\nRecipe content in this development edition uses the public educational/developer key. Not licensed here for app-store distribution.',
          ),
          if (snapshot.hasData)
            for (final credit in jsonDecode(snapshot.data![0]) as List)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SelectableText(
                  '${credit['id']}\n${credit['author']}\n${credit['license']}\n${credit['source']}\n${credit['licenseUrl']}\n${credit['changes']}',
                ),
              ),
          if (snapshot.hasData)
            for (final recipe
                in (jsonDecode(snapshot.data![1]) as Map)['recipes'] as List)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SelectableText(
                  '${recipe['names']['en']}\n${recipe['source']['provider']}\n${recipe['source']['url']}\n${recipe['sourceUrl'] ?? ''}',
                ),
              ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => showLicensePage(context: context),
            child: const Text('Open-source software licenses'),
          ),
        ],
      ),
    ),
  );
}
