import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {boundedPracticalReply} from './response-quality.mjs';
import {validateReply} from './coach.mjs';
const legacyUrl=new URL('./fixtures/synthetic-live-20261124.json',import.meta.url);
const fixture=fs.existsSync(legacyUrl)?JSON.parse(fs.readFileSync(legacyUrl)):null;
test('historical Llama capture, original archive fixture unavailable when skipped',{skip:fixture===null},()=>{
 assert.equal(fixture.results.length,4);
 assert.equal(fixture.results.filter(e=>{const r=e.body.output.response;return !boundedPracticalReply((typeof r==='string'?JSON.parse(r):r).text)}).length,2);
 for(const entry of fixture.results){
 assert.equal(entry.status,200);
 const raw=entry.body.output.response;const decoded=typeof raw==='string'?JSON.parse(raw):raw;
 if(!boundedPracticalReply(decoded.text)){assert.throws(()=>validateReply(raw,[]));}else{
 const reply=validateReply(raw,[]);assert.equal(reply.origin,'ai');assert.equal(reply.requiresUserReview,true);}
 assert.throws(()=>validateReply(entry.body.output,[]));
 }
});

const gemma=JSON.parse(fs.readFileSync(new URL('./fixtures/gemma-live-20261125.json',import.meta.url)));
test('current captured synthetic Gemma replies preserve schema and model provenance',()=>{
 assert.equal(gemma.results.length,3);
 for(const result of gemma.results){
  assert.equal(result.status,200);assert.equal(result.body.model,'@cf/google/gemma-4-26b-a4b-it');
  assert.equal(result.body.origin,'ai');
  const {text,sourceIds,navigation}=result.body;
  assert.equal(validateReply({text,sourceIds,navigation}).text,text);
 }
 assert.equal(gemma.checks.unauth,403);assert.equal(gemma.checks.unapprovedContext,403);
});
