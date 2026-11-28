# 09 — Data Flow & System Behavior

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

Every diagram below describes the system as implemented in the repository, not a design aspiration.

---

## 1. Use Case Diagram

```mermaid
flowchart LR
    User((Registered<br/>User))
    Guest((New<br/>User))

    subgraph Sufra["Sufra system"]
        UC1("Create account / sign in<br/>(email + Google)")
        UC2("Reset password<br/>by email code")
        UC3("Complete health profile")
        UC4("Log a meal: search")
        UC5("Log a meal: voice")
        UC6("Log a meal: barcode")
        UC7("Log a meal: photo")
        UC8("Save favorites")
        UC9("View diary & stats")
        UC10("Track water & weight")
        UC11("Export PDF report")
        UC12("Generate meal plan")
        UC13("Manage shopping list")
        UC14("Chat with the coach")
        UC15("Find healthier alternatives")
        UC16("Use Ramadan mode")
        UC17("Earn achievements")
        UC18("Manage reminders")
        UC19("Switch theme & language")
    end

    Guest --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    User --> UC5
    User --> UC6
    User --> UC7
    User --> UC8
    User --> UC9
    User --> UC10
    User --> UC11
    User --> UC12
    User --> UC13
    User --> UC14
    User --> UC15
    User --> UC16
    User --> UC17
    User --> UC18
    User --> UC19
```

**Actor descriptions:**
- **New User:** anyone installing the app; can create an account or continue to sign in.
- **Registered User:** a signed-in account owner; all personal data is scoped to their UID by Firestore rules.
- **Supporting system actors** (not shown for clarity): Firebase Auth (identity), Cloudflare Workers (reset-code, health-coach, food-vision), Workers AI (Gemma 4, Qwen 3.8), Open Food Facts (barcode data), USDA (catalog nutrition), SMTP (reset emails).

---

## 2. Data Flow Diagrams

### DFD Level 0 (context)

```mermaid
flowchart TB
    U(["User"])
    SUFRA(("Sufra<br/>System"))
    FA["Firebase Auth"]
    FS["Cloud Firestore"]
    ST["Cloud Storage"]
    W["Cloudflare Workers<br/>+ Workers AI"]
    OFF["Open Food Facts"]
    USDA["USDA FoodData Central"]
    MAIL["SMTP email"]

    U -->|"credentials, meals, photos (with consent), questions"| SUFRA
    SUFRA -->|"diary, stats, plans, coach replies, reports"| U
    SUFRA -->|"sign-in, token verification"| FA
    SUFRA -->|"owner-scoped reads/writes"| FS
    SUFRA -->|"user images"| ST
    SUFRA -->|"ID-token-authorized AI requests"| W
    SUFRA -->|"barcode lookup"| OFF
    FS -.->|"seeded catalog"| USDA
    W -->|"6-digit reset code"| MAIL
    MAIL -->|"reset email"| U
```

### DFD Level 1

```mermaid
flowchart TB
    U(["User"])

    P1["1.0<br/>Account & Profile"]
    P2["2.0<br/>Meal Logging"]
    P3["3.0<br/>Tracking & Stats"]
    P4["4.0<br/>Planning & Shopping"]
    P5["5.0<br/>AI Services"]

    D1[("users/{uid} profile")]
    D2[("meal_entries / daily_logs")]
    D3[("water / weight logs")]
    D4[("meal_plans / shopping_lists")]
    D5[("food_catalog / products (read-only)")]
    D6[("conversations")]
    D7[("Workers KV: hashed reset codes")]

    U --> P1
    P1 <--> D1
    P1 -->|"reset request / confirm"| D7
    U --> P2
    P2 <--> D5
    P2 --> D2
    P2 -->|"photo + ID token"| P5
    P3 <--> D2
    P3 <--> D3
    U --> P3
    P4 <--> D4
    P4 <--> D5
    U --> P4
    U -->|"question + context"| P5
    P5 -->|"coach reply"| D6
    P5 -->|"recognized items"| P2
```

---

## 3. Sequence Diagrams

### 3.1 Log a meal by photo (AI recognition)

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant App as Flutter app
    participant Prep as MealImagePreparer
    participant FV as food-vision Worker
    participant AI as Workers AI
    participant FS as Firestore

    U->>App: Photograph the plate
    App->>U: Ask consent to upload
    U->>App: Consent
    App->>Prep: Resize & encode JPEG
    App->>FV: POST /recognize (image/jpeg + Bearer ID token)
    FV->>FV: Verify Firebase token, rate limit, validate JPEG
    FV->>AI: Recognize (Gemma 4)
    FV->>AI: Self-verification pass on the first reading
    alt first model fails
        FV->>AI: Silent fallback (Qwen 3.8)
    end
    FV-->>App: Candidate items (or honest empty result)
    App->>FS: Match candidates to food_catalog
    App->>U: Review screen: edit, add, delete, confirm quantities
    U->>App: Confirm
    App->>FS: Save meal_entries + update daily_logs
    App->>U: Diary updated
```

### 3.2 Coach chat

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant App as Flutter app
    participant HC as health-coach Worker
    participant Tool as Catalog calculation tool
    participant G as Workers AI (Gemma 4)
    participant FS as Firestore

    U->>App: Ask a question (Egyptian Arabic or English)
    App->>HC: POST /chat {question, locale, consentVersion, context}
    HC->>HC: Validate input contract + safety preflight
    HC->>Tool: Compute nutrition deterministically (when asked)
    Tool-->>HC: Reviewed calculation (numbers stay server-side)
    HC->>G: Explain using provided context and sources only
    G-->>HC: Draft reply
    HC->>HC: Validate output contract: no numbers, no links,<br/>sourceIds from server list, navigation enum
    alt contract violated
        HC->>G: One corrective retry naming the target language
    end
    HC-->>App: {text, sourceIds, navigation, requiresUserReview}
    App->>U: Reply shown; numbers rendered by the app from the tool
    App->>FS: Append to conversations/messages
```

### 3.3 Barcode product lookup

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant App as Flutter app
    participant FS as Firestore (products)
    participant OFF as Open Food Facts

    U->>App: Scan barcode
    App->>FS: Get products/{barcode}
    alt cached
        FS-->>App: Product record
    else miss
        App->>OFF: Lookup by barcode (with contact identification)
        OFF-->>App: Product data
    end
    App->>U: Product page: Nutri-Score, ingredients, allergens
    U->>App: Log a portion / save to favorites
```

### 3.4 Password reset by email code

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant App as Flutter app
    participant RC as reset-code Worker
    participant KV as Workers KV
    participant IT as Google Identity Toolkit
    participant M as SMTP

    U->>App: Forgot password, enter email
    App->>RC: POST /request {email}
    RC->>RC: Rate limit: one request per email per 60 s
    RC->>IT: Lookup account by email
    RC->>KV: Store hash(code, email, secret), uid, TTL 5 min
    RC->>M: Send bilingual email with the 6-digit code
    RC-->>App: {ok: true, expiresIn: 300} (same for unknown emails)
    M-->>U: Email arrives
    U->>App: Enter 6 digits (OTP boxes), set new password
    App->>RC: POST /confirm {email, code, newPassword}
    RC->>KV: Compare hash, check expiry and attempts
    RC->>IT: Update password
    RC->>KV: Delete the used code
    RC-->>App: {ok: true}
    App->>U: Sign in with the new password
```

---

## 4. Activity Diagram — log a meal (all five methods)

```mermaid
flowchart TD
    Start([Open meal logging]) --> Choice{Choose method}
    Choice -->|Search| S1[Search Egyptian catalog<br/>Arabic or English]
    Choice -->|Voice| S2[Speak the meal<br/>transcribe + suggest matches]
    Choice -->|Barcode| S3[Scan product<br/>local products, then Open Food Facts]
    Choice -->|Photo| S4{Consent to upload?}
    Choice -->|Favorites| S5[Pick a saved favorite]
    S4 -->|No| S1
    S4 -->|Yes| S6[Prepare image, recognize, self-verify]
    S6 --> S7{Food found?}
    S7 -->|No| S8[Honest empty state:<br/>search or log manually]
    S8 --> S1
    S7 -->|Yes| S9
    S1 --> S9[Review: items, servings, quantities]
    S2 --> S9
    S3 --> S9
    S5 --> S9
    S9 --> S10{Confirm?}
    S10 -->|Edit| S9
    S10 -->|Yes| S11[Save meal entry<br/>update daily totals]
    S11 --> End([Diary updated])
```

---

## 5. State Diagram — photo meal recognition

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> ConsentPending: user picks photo
    ConsentPending --> PreparingImage: consent given
    ConsentPending --> Idle: declined (stays on device)
    PreparingImage --> Analyzing: JPEG ready
    Analyzing --> Verifying: first reading returned
    Analyzing --> FallbackModel: model error or contract break
    FallbackModel --> Verifying: fallback reading returned
    FallbackModel --> Unavailable: all models failed
    Verifying --> ReviewReady: verification passed
    Verifying --> EmptyHonest: no food confirmed
    ReviewReady --> Editing: user adjusts items
    Editing --> ReviewReady: edits done
    ReviewReady --> Saving: user confirms
    Saving --> Saved: meal entry + daily totals written
    EmptyHonest --> Idle: search or manual logging offered
    Unavailable --> Idle: calm message, manual options
    Saved --> [*]
```

**Notes:** "EmptyHonest" and "Unavailable" are deliberate end states, not error crashes: the app's principle is that an unknown answer is shown honestly and the user always has a manual path. Nothing is saved before the user confirms.

---

## 6. Class Diagram — core domain model

```mermaid
classDiagram
    class UserProfileModel {
        +String uid
        +String displayName
        +String? email
        +String preferredLanguage
        +String timezone
        +String measurementSystem
        +Map~String,bool~ notificationPreferences
        +bool onboardingCompleted
        +String accountStatus
        +DateTime? createdAt
    }
    class NutritionProfileModel {
        +String profileId
        +String gender
        +DateTime dateOfBirth
        +double heightCm
        +double currentWeightKg
        +double targetWeightKg
        +String activityLevel
        +String nutritionGoal
        +double dailyCalorieTarget
        +double proteinTarget
        +double carbsTarget
        +double fatTarget
        +List~String~ allergies
        +bool isActive
    }
    class MealEntryModel {
        +String mealId
        +String userId
        +String dateKey
        +DateTime consumedAt
        +String mealType
        +String inputMethod
        +String title
        +String? imageUrl
        +List~MealItemModel~ items
        +double totalCalories
        +double? totalProtein
    }
    class MealItemModel {
        +String foodId
        +String foodName
        +double quantity
        +String unit
        +double weightInGrams
        +double calories
        +double? protein
        +String dataSource
        +double? confidence
    }
    class DailyLogModel {
        +String dateKey
        +String timezone
        +double? totalCalories
        +double calorieTarget
        +double proteinTarget
        +double waterIntakeMl
        +int mealCount
        +DateTime? updatedAt
    }
    class WaterLogModel {
        +String waterId
        +double amountMl
        +DateTime consumedAt
        +String dateKey
    }
    class WeightLogModel {
        +String weightId
        +double weightKg
        +DateTime recordedAt
        +String dateKey
        +String? note
    }
    class MealPlanModel {
        +String planId
        +String title
        +DateTime startDate
        +DateTime endDate
        +String status
        +double dailyCalorieTarget
        +List~MealPlanMealModel~ meals
        +String generatedBy
    }
    class MealPlanMealModel {
        +String mealId
        +String title
        +String mealType
        +double calories
        +List~String~ foods
        +List~MealPlanFoodPortion~ foodPortions
        +String? dateKey
    }
    class ShoppingListModel {
        +String listId
        +String title
        +String? planId
        +String status
    }
    class ShoppingListItemModel {
        +String itemId
        +String name
        +double quantity
        +String unit
        +String category
        +bool isPurchased
        +String linkedFoodId (nullable)
        +String productBarcode (nullable)
    }
    class FavoriteModel {
        +String favoriteId
        +String targetId
        +String targetType
        +String title
    }
    class FoodCatalogModel {
        +String foodId
        +String name
        +Map localizedNames
        +String? category
        +String? sourceUrl
        +Map servingSizes
        +Map nutritionPer100g
        +String? source
        +String? verificationStatus
    }
    class ConversationModel {
        +String conversationId
        +String title
        +DateTime? lastMessageAt
    }
    class ChatMessageModel {
        +String messageId
        +String role
        +String content
        +String messageType
        +DateTime? createdAt
    }
    class AchievementModel {
        +String achievementId
        +String achievementType
        +String title
        +double progress
        +double target
        +bool isUnlocked
    }
    class DeviceModel {
        +String deviceId
        +String fcmToken
        +String platform
        +bool isActive
    }
    class AppNotificationModel {
        +String notificationId
        +String title
        +String body
        +String type
        +bool isRead
    }

    UserProfileModel "1" --> "*" NutritionProfileModel
    UserProfileModel "1" --> "*" MealEntryModel
    UserProfileModel "1" --> "*" DailyLogModel
    UserProfileModel "1" --> "*" WaterLogModel
    UserProfileModel "1" --> "*" WeightLogModel
    UserProfileModel "1" --> "*" MealPlanModel
    UserProfileModel "1" --> "*" ShoppingListModel
    UserProfileModel "1" --> "*" FavoriteModel
    UserProfileModel "1" --> "*" AchievementModel
    UserProfileModel "1" --> "*" ConversationModel
    UserProfileModel "1" --> "*" DeviceModel
    UserProfileModel "1" --> "*" AppNotificationModel
    MealEntryModel "1" *-- "*" MealItemModel
    MealPlanModel "1" *-- "*" MealPlanMealModel
    ShoppingListModel "1" *-- "*" ShoppingListItemModel
    ConversationModel "1" *-- "*" ChatMessageModel
    FoodCatalogModel "1" <-- "*" MealItemModel : dataSource
```

Optional fields are marked with `?`, matching the models in `lib/data/models/`. Nullable nutrition fields are meaningful: an absent value is an honest unknown, never a silent zero.
