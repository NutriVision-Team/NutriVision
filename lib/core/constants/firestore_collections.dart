class FirestoreCollections {
  static const String users = 'users';
  static const String nutritionProfiles = 'nutrition_profiles';
  static const String mealEntries = 'meal_entries';
  static const String dailyLogs = 'daily_logs';
  static const String weightLogs = 'weight_logs';
  static const String waterLogs = 'water_logs';
  static const String mealPlans = 'meal_plans';
  static const String shoppingLists = 'shopping_lists';
  static const String favorites = 'favorites';
  static const String notifications = 'notifications';
  static const String devices = 'devices';
  static const String achievements = 'achievements';
  static const String conversations = 'conversations';
  static const String foodCatalog = 'food_catalog';
  static const String products = 'products';
  static const String recipes = 'recipes';
  static const String foodCategories = 'food_categories';
  static const String appConfig = 'app_config';

  static String userDocument(String uid) => '$users/$uid';
  static String nutritionProfileDocument(String uid, String profileId) =>
      '$users/$uid/$nutritionProfiles/$profileId';
  static String mealEntryDocument(String uid, String mealId) =>
      '$users/$uid/$mealEntries/$mealId';
  static String dailyLogDocument(String uid, String dateKey) =>
      '$users/$uid/$dailyLogs/$dateKey';
  static String weightLogDocument(String uid, String weightId) =>
      '$users/$uid/$weightLogs/$weightId';
  static String waterLogDocument(String uid, String waterId) =>
      '$users/$uid/$waterLogs/$waterId';
  static String mealPlanDocument(String uid, String planId) =>
      '$users/$uid/$mealPlans/$planId';
  static String shoppingListDocument(String uid, String listId) =>
      '$users/$uid/$shoppingLists/$listId';
  static String favoriteDocument(String uid, String favoriteId) =>
      '$users/$uid/$favorites/$favoriteId';
  static String notificationDocument(String uid, String notificationId) =>
      '$users/$uid/$notifications/$notificationId';
  static String deviceDocument(String uid, String deviceId) =>
      '$users/$uid/$devices/$deviceId';
  static String achievementDocument(String uid, String achievementId) =>
      '$users/$uid/$achievements/$achievementId';
  static String conversationDocument(String uid, String conversationId) =>
      '$users/$uid/$conversations/$conversationId';
}
