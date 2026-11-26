class CoachLearnSection {
  const CoachLearnSection(this.titleAr, this.titleEn, this.bodyAr, this.bodyEn);
  final String titleAr, titleEn, bodyAr, bodyEn;
}

class CoachLearnTopic {
  const CoachLearnTopic({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.sections,
    required this.sourceName,
    required this.sourceUrl,
    required this.actionRoute,
    required this.actionAr,
    required this.actionEn,
  });
  final String id,
      titleAr,
      titleEn,
      sourceName,
      sourceUrl,
      actionRoute,
      actionAr,
      actionEn;
  final List<CoachLearnSection> sections;
}

/// Brief app-authored summaries of the cited official general-population pages.
/// Not translations, clinical guidance or specialist-reviewed app content.
const coachLearnTopics = <CoachLearnTopic>[
  CoachLearnTopic(
    id: 'balance',
    titleAr: 'التوازن على مدار اليوم',
    titleEn: 'Balance across your day',
    sourceName: 'NHS: The Eatwell Guide',
    sourceUrl:
        'https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/the-eatwell-guide/',
    actionRoute: '/planner',
    actionAr: 'افتح مخطط الوجبات',
    actionEn: 'Open meal planner',
    sections: [
      CoachLearnSection(
        'مش لازم كل وجبة تكون مثالية',
        'Not every meal needs to be perfect',
        'التوازن بيتبص له على مدار اليوم أو الأسبوع، مش وجبة واحدة. نوّع بين المجموعات الغذائية بدل الاعتماد على صنف واحد.',
        'Balance can be considered over a day or week rather than one meal. Choose variety across food groups rather than relying on one food.',
      ),
      CoachLearnSection(
        'اختيارات مختلفة',
        'Different food groups',
        'المصدر بيجمع الخضار والفاكهة، النشويات، مصادر البروتين، الألبان أو بدائلها، وكميات صغيرة من الزيوت والدهون غير المشبعة. دي معلومات عامة، مش حصص شخصية ليك.',
        'The guide includes fruit and vegetables, starchy foods, protein foods, dairy or alternatives, and small amounts of unsaturated oils and spreads. This is general information, not your personal portion plan.',
      ),
    ],
  ),
  CoachLearnTopic(
    id: 'fiber',
    titleAr: 'الألياف والبروتين من الأكل',
    titleEn: 'Fiber and protein from food',
    sourceName: 'NHS: Eating a balanced diet',
    sourceUrl:
        'https://www.nhs.uk/live-well/eat-well/how-to-eat-a-balanced-diet/eating-a-balanced-diet/',
    actionRoute: '/food-search',
    actionAr: 'استكشف قاعدة الأكل',
    actionEn: 'Explore food database',
    sections: [
      CoachLearnSection(
        'البقول والحبوب',
        'Pulses and grains',
        'الفول والعدس والبقول بتوفر بروتين وألياف. اختيارات الحبوب الكاملة بتساعدك تضيف ألياف، زي الأرز البني والمكرونة كاملة الحبة. راجع المكونات لو عندك حساسية.',
        'Beans, lentils and other pulses provide protein and fiber. Wholegrain choices, such as brown rice and wholewheat pasta, can add fiber. Check ingredients if you have allergies.',
      ),
      CoachLearnSection(
        'الناقص في السجل',
        'Missing in the record',
        'لو قاعدة الأكل مش فيها قيمة للألياف، سفرة بيعرضها غير معروفة. مش معنى كده إن الوجبة خالية من الألياف. راجع تفاصيل المصدر والكميات اللي سجلتها.',
        'If a food record lacks a fiber value, Sufra shows it as unknown. That does not mean the meal contains no fiber. Review the source details and portions you recorded.',
      ),
    ],
  ),
  CoachLearnTopic(
    id: 'labels',
    titleAr: 'اقرأ ملصق الأكل',
    titleEn: 'Read a food label',
    sourceName: 'NHS: Food labels',
    sourceUrl:
        'https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/how-to-read-food-labels/',
    actionRoute: '/food-search',
    actionAr: 'ابحث عن الأكل',
    actionEn: 'Search foods',
    sections: [
      CoachLearnSection(
        'نفس أساس المقارنة',
        'Compare the same basis',
        'راجع هل الأرقام لكل ١٠٠ جم أو ١٠٠ مل، ولا للحصة. الحصة المكتوبة على العبوة ممكن تختلف عن اللي أكلته. قارن منتجين على نفس الأساس.',
        'Check whether values are per 100 g, per 100 ml or per serving. The serving on the package may differ from what you ate. Compare products on the same basis.',
      ),
      CoachLearnSection(
        'مش السعرات بس',
        'Beyond calories',
        'بص على الدهون المشبعة والسكريات والملح، وكمان البروتين والألياف لو متاحة. راجع قائمة المكونات والحساسية على العبوة الأصلية، مش الاسم أو نتيجة البحث بس. قواعد وتنسيق الملصقات ممكن يختلفوا حسب البلد.',
        'Look at saturated fat, sugars and salt, as well as protein and fiber when listed. Check ingredients and allergens on the original package, not only the product name or search result. Label rules and formats can differ by country.',
      ),
    ],
  ),
  CoachLearnTopic(
    id: 'water',
    titleAr: 'المية والمشروبات',
    titleEn: 'Water and drinks',
    sourceName: 'NHS: Water, drinks and hydration',
    sourceUrl:
        'https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/water-drinks-nutrition/',
    actionRoute: '/water',
    actionAr: 'افتح سجل المية',
    actionEn: 'Open water log',
    sections: [
      CoachLearnSection(
        'اشرب خلال اليوم',
        'Drink through the day',
        'المية اختيار مناسب للترطيب، ومشروبات وأطعمة تانية بتساهم في السوائل كمان. المصدر بينصح بالشرب بانتظام خلال اليوم. الاحتياج بيختلف مع الجو والنشاط والظروف الشخصية.',
        'Water is a suitable hydration choice, and other drinks and foods contribute fluid too. The source suggests drinking regularly through the day. Needs vary with heat, activity and personal circumstances.',
      ),
      CoachLearnSection(
        'الهدف مش للجميع',
        'No single target for everyone',
        'هدف المية الافتراضي في التطبيق مش وصفة شخصية. لو مختص محددلك كمية أو قيود للسوائل، اتبع تعليماته. سجل اللي شربته فعلًا بدل ما تعتبر الهدف استهلاك.',
        'The app default water goal is not a personal prescription. Follow your clinician\'s instructions if you have a fluid limit or target. Log what you actually drank rather than treating a goal as consumption.',
      ),
    ],
  ),
  CoachLearnTopic(
    id: 'safety',
    titleAr: 'خمس خطوات لأكل أكثر أمانًا',
    titleEn: 'Five keys to safer food',
    sourceName: 'WHO: Five keys to safer food',
    sourceUrl:
        'https://www.who.int/activities/promoting-safe-food-handling/five-key-to-safer-food',
    actionRoute: '/recipes',
    actionAr: 'استكشف الوصفات',
    actionEn: 'Explore recipes',
    sections: [
      CoachLearnSection(
        'النظافة والفصل',
        'Clean and separate',
        'حافظ على النظافة وافصل الأكل النيّ عن المطبوخ. ده يشمل الأدوات والأسطح اللي بتلمس الأكل.',
        'Keep clean and separate raw and cooked food, including the utensils and surfaces that touch them.',
      ),
      CoachLearnSection(
        'التسوية والحفظ',
        'Cook and store safely',
        'سوّي الأكل كويس، واحفظه في درجات حرارة آمنة، واستخدم مياه وخامات آمنة. افتح مصدر منظمة الصحة العالمية للتفاصيل، واتبع تعليمات العبوة والحفظ المناسبة للأكل.',
        'Cook thoroughly, keep food at safe temperatures, and use safe water and raw materials. Open the WHO source for details and follow the food\'s package and storage instructions.',
      ),
    ],
  ),
  CoachLearnTopic(
    id: 'variety',
    titleAr: 'التنوع مش رقم مكونات',
    titleEn: 'Variety is more than a count',
    sourceName: 'WHO: Healthy diet',
    sourceUrl: 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet',
    actionRoute: '/recipes',
    actionAr: 'اختار وصفة تناسبك',
    actionEn: 'Choose a recipe',
    sections: [
      CoachLearnSection(
        'مبادئ عامة',
        'General principles',
        'منظمة الصحة العالمية بتوصف الكفاية والتوازن والاعتدال والتنوع كمبادئ للأكل الصحي. شكل الأكل المناسب بيتغير حسب الشخص والثقافة والمتاح.',
        'WHO describes adequacy, balance, moderation and diversity as healthy-diet principles. Suitable food patterns vary with the person, culture and available foods.',
      ),
      CoachLearnSection(
        'استخدم السجل بحذر',
        'Use your record carefully',
        'عدد المكونات اللي في سجلك وصف للبيانات المتاحة، مش تقييم للتوازن أو دليل إن هدفك اتحقق. لما تختار وصفة أو بديل، راجع المكونات والكميات والحساسية وتعليمات مختصك.',
        'The ingredient count in your record describes available data. It is not a balance score or proof of a completed goal. When choosing a recipe or alternative, review ingredients, portions, allergies and professional guidance.',
      ),
    ],
  ),
];
