# 03 — Task Assignment & Roles

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

Ownership is defined over the 31 numbered screens of the design system (`design/Sufra_Design_UI_fast.html`). Each member owns the implementation of their screens end to end: layout, state, localization, tests, and fixes found in reviews.

---

## Team structure

| Member | Role | Screens | Scope |
|---|---|---|---|
| **Mostafa Ghonime** | **Team Leader** | 21–29 | Planning & tracking core: weekly planner, shopping, water, weight, progress, PDF report, coach, achievements, Ramadan. Plus architecture, backend Workers, AI integration, code review and repository hygiene |
| Mohamed Osama | Developer | 1–5 | Entry experience: splash, welcome carousel, login, register, welcome-back |
| Abdelrahman | Developer | 6–10 | Personal setup and home: setup wizard, plan, home, logging method, search |
| Ahmed Abdelnasser | Developer | 11–15 | Photo logging and diary: camera & analysis, meal review, diary, meal detail, barcode scanner |
| George Karam | Developer | 16–20 | Discovery: product result, alternatives, meal suggestion, recipe, favorites |
| Mohamed Ghazy | Developer | 30–31 | Export flow and Premium screen |

The leader additionally owns the shared foundation every screen builds on: the design token system, the component library, routing and back behavior, the backend Workers, security rules, and the final review pass.

## The 31 screens

| # | Screen | # | Screen |
|---|---|---|---|
| 1 | البداية (Splash) | 17 | البدائل (Alternatives) |
| 2 | ترحيب (Welcome carousel, 3 variants) | 18 | اقترح وجبة (Meal suggestion) |
| 3 | تسجيل الدخول (Login) | 19 | الوصفة (Recipe) |
| 4 | إنشاء حساب (Register) | 20 | المفضلة (Favorites) |
| 5 | أهلاً بيك (Welcome) | 21 | خطة الأسبوع (Weekly planner) |
| 6 | الإعداد الشخصي (Personal setup) | 22 | التسوق (Shopping) |
| 7 | خطتك (Your plan) | 23 | المية (Water) |
| 8 | الرئيسية (Home) | 24 | الوزن (Weight) |
| 9 | طريقة التسجيل (Logging method) | 25 | تقدمي (Progress) |
| 10 | بحث (Search) | 26 | التقرير (Report) |
| 11 | التصوير والتحليل (Camera & analysis) | 27 | المدرّب (Coach) |
| 12 | راجع وجبتك (Review your meal) | 28 | الإنجازات (Achievements) |
| 13 | اليومية (Diary) | 29 | رمضان (Ramadan) |
| 14 | تفاصيل الوجبة (Meal detail) | 30 | تصدير (Export) |
| 15 | الباركود (Barcode scanner) | 31 | بريميوم (Premium) |
| 16 | نتيجة المنتج (Product result) | | |

## Responsibilities matrix

| Responsibility | Owner |
|---|---|
| Screen implementation (per table above) | Each member |
| Architecture, design tokens, component library | Team Leader |
| Backend Workers (reset-code, health-coach, food-vision, progression) | Team Leader |
| AI model selection, prompts, output contracts | Team Leader |
| Firestore/Storage security rules | Team Leader |
| Code review, merge decisions, analyzer-clean gate | Team Leader |
| Test coverage per screen | Each member for their screens |
| Full-app review passes (responsive matrix, security) | Team (26 Nov review is the recorded example) |
| Documentation (this set) | Team Leader, reviewed by the team |
| Client/instructor demos | Team Leader |

## Collaboration rules (as practiced)

- Work lands on `main` through reviewed commits; the repo history is the record.
- Every screen ships with its tests in the same change.
- Design fidelity is measured against the HTML design system, not personal taste.
- A defect found in review gets a fix and a test in the same pass (see 12 Testing & QA, bug table).
