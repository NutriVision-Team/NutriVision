#!/bin/sh
# Run from the project root with Flutter's Dart SDK on PATH before a web build.
# Native builds do not load this asset. No account, deploy or network operation.
set -eu
dart compile js --packages=.dart_tool/package_config.json -O2 --no-source-maps -o web/meal_image_worker.js tool/meal_image_worker.dart
rm -f web/meal_image_worker.js.deps
