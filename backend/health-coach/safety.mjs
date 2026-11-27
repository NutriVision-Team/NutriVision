// Conservative defense in depth, not a clinical classifier or certification.
const normalize = text => text.toLowerCase().normalize('NFKC').replace(/[أإآ]/g,'ا').replace(/[ً-ْ]/g,'');
export function safetyPreflight(input) {
  const ar=input.locale==='ar';
  const q=normalize(input.question);
  if (['chest pain','cannot breathe',"can't breathe",'anaphylaxis','suicid','الم في الصدر','مش قادر اتنفس','اختناق','اغماء','انتحار'].some(s=>q.includes(s))) {
    return ar ? 'الأعراض دي ممكن تحتاج مساعدة عاجلة. اطلب الطوارئ المحلية أو مساعدة شخص قريب دلوقتي، وما تستناش المدرب.' : 'These symptoms may need urgent care. Contact local emergency services or ask someone nearby for help now. Do not wait for this coach.';
  }
  if (['insulin dose','change my dose','stop medication','diagnose','starve','purge','جرعة','جرعه','تشخيص','اوقف الدواء','وقف الدوا','تجويع','تقيؤ'].some(s=>q.includes(s)) || /(?:[0-9٠-٩]+)\s*(?:calorie|kcal|سعر)/u.test(q)) {
    return ar ? 'مش هقدر أشخّص أو أحدد دواء أو حمية قاسية. راجع مختص مؤهل. أقدر أساعد في تنظيم سجلك وأسئلتك ليه.' : 'I cannot diagnose, prescribe or support extreme diets. Consult a qualified professional. I can help organize your records and questions for them.';
  }
  const severeAllergy = /(?:severe|serious).{0,35}allerg|(?:allerg).{0,35}(?:severe|serious)|حساسي[ةه].{0,40}(?:شديد|مفرط)/u.test(q);
  if(severeAllergy) return ar
    ? 'مش هقدر أأكد إن الوجبة آمنة لحساسية شديدة. اتأكد من المكونات واحتمال التلامس مع مسبب الحساسية مع مقدم الأكل، ولو مش متأكد بلاش تعتمد على الرد ده أو الصورة. اتبع خطة طبيبك، ولو فيه أعراض طارئة اطلب الطوارئ فورًا.'
    : 'I cannot confirm a meal is safe for a severe allergy. Check ingredients and possible cross-contact with whoever prepared it. If unsure, do not rely on this chat or a photo. Follow your clinician\'s plan; for emergency symptoms seek emergency help now.';
  const p=input.context.profile;
  const risk=p && ((p.age!==undefined&&p.age<18)||(p.conditions?.length>0));
  const disclosed=['pregnan','breastfeed','kidney disease','diabet','eating disorder','حامل','رضاعة','رضاعه','كلى','سكري','سكر','اضطراب اكل'].some(s=>q.includes(s));
  const plan=['plan','diet','weight loss','خطة','خس','رجيم'].some(s=>q.includes(s));
  if(plan&&(risk||disclosed)) return ar ? 'الظروف الصحية دي تحتاج خطة يراجعها مختص، مش خطة علاج أو وزن مستقلة من المدرب. نقدر ننظم السجلات بدون تغيير تعليمات المختص.' : 'This situation needs a plan reviewed by a qualified professional, not an independent treatment or weight plan from this coach. We can organize records without changing professional guidance.';
  return null;
}
export function outputSafe(text) {
  const t=normalize(text);
  return !/[0-9٠-٩۰-۹]|https?:\/\/|www\.|[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Cyrillic}\u00c0-\u024f\u1e00-\u1eff]|<[^>]+>|```/u.test(t) && !['stop your medication','increase your dose','double your dose','you have diabetes','you have cancer','guaranteed safe','allergy free','allergen-free','cures diabetes','purge','اوقف الدواء','وقف الدوا','زود الجرعة','زود الجرعه','ضاعف الجرعة','انت عندك سكر','امن تماما','خالي من الحساسية','يعالج السكر','تجويع','تقيؤ'].some(s=>t.includes(s));
}
