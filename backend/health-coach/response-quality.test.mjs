import test from 'node:test';import assert from 'node:assert/strict';import {consistentMealTiming} from './response-quality.mjs';
test('known contradictory Arabic and English meal timing is rejected',()=>{
 for(const text of ['تجنب الأكل بين الوجبات. كما يمكنك تناول وجبات صغيرة وموزعة على مدار اليوم.','Avoid snacking. Have small frequent meals.'])assert.equal(consistentMealTiming(text),false);
});
test('flexible nonprohibitive suggestions remain available',()=>{assert.equal(consistentMealTiming('جرب تختار معاد مناسب لوجبة واحدة حسب يومك. لو بتجوع بين الوجبات، ممكن تختار سناك مناسب.'),true)});

import {boundedPracticalReply,QUESTION_FOCUS_GUIDANCE} from './response-quality.mjs';
test('bounded candidate rejects long digressions and blanket food rules',()=>{
 assert.equal(boundedPracticalReply('x'.repeat(421)),false);
 assert.equal(boundedPracticalReply('Never eat snacks.'),false);
 assert.equal(boundedPracticalReply('كل المطاعم غير صحية'),false);
 assert.equal(boundedPracticalReply('مش لازم تمنع السناك. جرب تختار معاد مناسب ليك.'),true);
 assert.ok(QUESTION_FOCUS_GUIDANCE.includes('Do not repeat the same suggestion'));
 assert.ok(QUESTION_FOCUS_GUIDANCE.includes('No stock answers')); 
});

import {nonRepetitiveReply} from './response-quality.mjs';
test('obvious repeated clauses and unfinished punctuation fail without rewriting',()=>{
 assert.equal(nonRepetitiveReply('اختار وجبة واحدة وخلي ليها معاد. اختار وجبة واحدة وخلي ليها معاد.'),false);
 assert.equal(nonRepetitiveReply('جرب تخطط لغداك،'),false);
 assert.equal(nonRepetitiveReply('اختار وجبة واحدة وخلي ليها معاد يناسب يومك. ابدأ بيها وشوف إيه اللي محتاج يتظبط.'),true);
});

import fs from 'node:fs';
import {validateReply} from './coach.mjs';
test('actual earlier Arabic captured reply fails narrow unfinished-response gate',()=>{
 const captured=JSON.parse(fs.readFileSync(new URL('../../test/features/health_coach/fixtures/typed_ar_live_20261125.json',import.meta.url)));
 assert.equal(captured.origin,'ai');
 assert.equal(nonRepetitiveReply(captured.text),false);
 assert.throws(()=>validateReply({text:captured.text,sourceIds:[],navigation:[]}));
});

import {modelMessages} from './coach.mjs';
test('message objects contain only provider role and content fields',()=>{
 for(const m of modelMessages({question:'Test',locale:'ar',context:{}})) assert.deepEqual(Object.keys(m).sort(),['content','role']);
});
