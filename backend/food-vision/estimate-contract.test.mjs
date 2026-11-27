import test from 'node:test';import assert from 'node:assert/strict';
import {estimatedCandidates,ESTIMATE_PROMPT} from './estimate-contract.mjs';
const raw=item=>({answer:JSON.stringify({items:[item]})});
const item={name:'cooked rice',foodState:'cooked',suggestedPortionGrams:150};
test('visual state and amount survive but model nutrition and confidence are stripped',()=>{
 const v=estimatedCandidates(raw({...item,confidence:1,calories:999,protein:999,matchedFoodId:'fake'}));
 assert.equal(v.requiresUserReview,true);assert.equal(v.items[0].suggestedPortionGrams,150);assert.equal(v.items[0].foodState,'cooked');assert.equal(v.items[0].confidence,null);assert.equal('calories' in v.items[0],false);assert.equal('matchedFoodId'in v.items[0],false);
});
test('malformed state and amount fail closed, unknown and unestimated allowed',()=>{
 for(const bad of [{...item,foodState:'fried-ish'},{...item,suggestedPortionGrams:0},{...item,suggestedPortionGrams:3001},{...item,uncertaintyNotes:['x'.repeat(501)]}])assert.throws(()=>estimatedCandidates(raw(bad)));
 assert.equal(estimatedCandidates(raw({...item,foodState:'unknown',suggestedPortionGrams:null})).items[0].suggestedPortionGrams,null);
});
test('prompt does not pretend image grams are measured or compose hidden recipe',()=>{assert.match(ESTIMATE_PROMPT,/rough visual estimate/);assert.match(ESTIMATE_PROMPT,/dish once with foodState prepared, not both/);assert.match(ESTIMATE_PROMPT,/Do not invent hidden oil, sugar, meat/)});

test('root array and absent amount are safe candidates, duplicates rejected',()=>{
 assert.equal(estimatedCandidates({answer:JSON.stringify([item])}).items.length,1);
 const {suggestedPortionGrams,...withoutGrams}=item;
 assert.equal(estimatedCandidates(raw(withoutGrams)).items[0].suggestedPortionGrams,null);
 assert.throws(()=>estimatedCandidates({answer:JSON.stringify({items:[item,{...item,name:'COOKED RICE'}]})}));
 assert.deepEqual(estimatedCandidates({answer:'{"items":[]}'}).items,[]);
});
