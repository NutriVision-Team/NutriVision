import {test} from 'node:test';import assert from 'node:assert/strict';
import {calculateReviewed} from './catalog-calculation.mjs';
import {safetyPreflight} from './safety.mjs';
import {modelMessages,validateInput} from './coach.mjs';
const selection=[{foodId:'usda_foundation_747997',grams:150}];
test('reviewed source tool recomputes and preserves unknown nutrients',()=>{const r=calculateReviewed(selection);assert.equal(r.energyKcal,82.5);assert.equal(r.proteinG,16.05);assert.equal(r.portions[0].nutrientsPer100g.fiberG,null);assert.equal(r.saved,false);});
test('selection rejects nutrient injection, duplicate unknown ids and invalid grams',()=>{for(const s of [[{...selection[0],energyKcal:1}],[selection[0],selection[0]],[{foodId:'invented',grams:1}],[{...selection[0],grams:-1}]])assert.throws(()=>calculateReviewed(s));});
test('structured catalog facts are not a calorie goal and medical protections remain',()=>{const input={question:'Explain the reviewed catalog calculation',locale:'en',consentVersion:'coach-external-v1',context:{reviewedCalculation:selection}};validateInput(input);assert.equal(safetyPreflight(input),null);assert.match(modelMessages(input)[1].content,/82.5/);for(const q of ['I want 500 kcal daily','change my dose','starve'])assert.ok(safetyPreflight({...input,question:q}));});

test('reviewed history is bounded and never contains raw identities',()=>{const h={from:'2026-11-01',to:'2026-11-25',confirmedMeals:2,recordedDays:1,energyKcal:200,proteinG:null,coverage:'recorded_confirmed_meals_only',missingDays:'unknown'};const input={question:'Review selected records',locale:'en',consentVersion:'coach-external-v1',context:{reviewedHistory:h}};assert.doesNotThrow(()=>validateInput(input));assert.equal(safetyPreflight(input),null);for(const patch of [{uid:'private'},{proteinG:-1},{missingDays:'zero'},{recordedDays:3},{from:'2027-01-01'}])assert.throws(()=>validateInput({...input,context:{reviewedHistory:{...h,...patch}}}));});
