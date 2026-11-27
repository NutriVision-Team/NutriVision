// Extra quality checks, not clinical certification. Explicitly reject a known
// contradictory meal-timing pattern; do not silently rewrite model replies.
export function consistentMealTiming(text) {
 const t=text.toLowerCase().replace(/[أإآ]/g,'ا').replace(/[ً-ْ]/g,'');
 const prohibit=/(?:تجنب|تجنّب|امتنع|بلاش|ممنوع|لا تاكل|متاكلش|ما تاكلش).{0,35}(?:بين الوجبات|بين وجبات)|(?:avoid|never|do not|don't).{0,25}(?:snack|between meals)/u.test(t);
 const distribute=/(?:وجبات صغيرة|وجبات خفيفة|وجبات خفيفه|سناك|موزعة|موزعه)|(?:small frequent meals|snacks between|distributed meals)/u.test(t);
 return !(prohibit&&distribute);
}
export const QUALITY_GUIDANCE = 'Keep the answer short, practical and internally consistent. Never recommend eating dried legumes after soaking alone or after partial cooking. If asked, advise following safe full cooking instructions, without inventing cooking times. Suggest one optional first step that fits the question, not a rigid diet. Do not give universal bans on snacking, eating between meals, eating after a clock time, or eating before sleep. Meal timing depends on personal circumstances that are not provided here. Do not invent named systems or imply drinking water suppresses hunger. Do not simultaneously forbid between-meal eating and recommend small frequent meals. For ar, write natural Egyptian Arabic, never mixed scripts. When no health context is shared, say so without pressuring disclosure. Do not claim personalization from unseen records.';

// Bound response size and blanket food rules. This is not a relevance judge.
export function boundedPracticalReply(text) {
 const t=text.toLowerCase().replace(/[أإآ]/g,'ا').replace(/[ً-ْ]/g,'');
 if(text.trim().length>420) return false;
 return !/(?:يجب دائما|لازم دايما|ممنوع تماما|never eat|always avoid|all restaurants are unhealthy|كل المطاعم غير صحية)/u.test(t);
}
export const QUESTION_FOCUS_GUIDANCE = '\nAnswer the actual question directly and naturally in the requested language. Keep the response concise but give enough detail to be useful. Do not repeat the same suggestion in different words. Do not assume ingredients, habits or circumstances not supplied. Ask one short clarification only when an essential detail is missing. Do not add generic meal preparation or schedule advice to unrelated questions. Do not claim access to unseen records. No stock answers, memorized answer examples or greetings unless greeted. No moral labels for food. Do not refer ordinary meal organization to a clinician.';

// Reject plainly duplicated clauses without rewriting the model response.
// This narrow text-quality gate is not a semantic or clinical evaluator.
export function nonRepetitiveReply(text) {
 const normalized = text.toLowerCase().replace(/[أإآ]/g, 'ا').replace(/[ً-ْ]/g, '').replace(/[.!?؟،,;؛:]/g, ' ');
 const words = normalized.trim().split(/\s+/u);
 const seen = new Set();
 for(let i=0;i+5<=words.length;i++) {
  const phrase=words.slice(i,i+5).join(' ');
  if(seen.has(phrase)) return false;
  seen.add(phrase);
 }
 return !/[،,;؛:]\s*$/u.test(text.trim());
}

export const ARABIC_FLUENCY_GUIDANCE = '\nلما اللغة ar: رد بالمصري الطبيعي بكلام بسيط وواضح يناسب سؤال الشخص. خلّي إجابتك من صياغتك أنت، من غير قوالب أو ردود محفوظة. راجع توافق الأفعال والضمائر وترابط الجمل قبل الإرسال، وابعد عن الترجمة الحرفية. ما تفترضش مكونات أو عادات أو ظروف الشخص. لو تفصيلة ضرورية ناقصة اسأل عنها بسؤال قصير. ما تذكرش عدم مشاركة السجلات إلا لو السؤال فعلًا محتاجها. خلي الرد مختصر ومفيد ومن غير تكرار.';

export const STYLE_ILLUSTRATIONS = '\nأمثلة اختيارية للأسلوب فقط، مش إجابات جاهزة ولا معلومات عن الشخص: «ممكن نبدأ بخطوة بسيطة تناسب يومك.» و«إيه المتاح عندك؟». ما تنقلش الأمثلة إلا لو معناها مناسب فعلًا. أنت تختار الأفكار والصياغة والتفاصيل حسب السؤال، ومش مطلوب تبدأ بكلمة معينة أو تسأل في كل رد. لو الإجابة واضحة جاوب مباشرة. حافظ على مصري طبيعي من غير تصنّع، وخليك مرن في عدد الجمل جوه حد الطول.';
