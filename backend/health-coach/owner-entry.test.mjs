import test from 'node:test';
import assert from 'node:assert/strict';
import worker,{validateBoundedContext} from './owner-entry.mjs';
import {outputSafe} from './safety.mjs';
const env={ENABLED:'true',FIREBASE_PROJECT_ID:'sufra-depi',ALLOWED_UIDS:'iJbaLiTtlugbL9DUwVQikCy1A633'};
test('owner backend rejects nonempty context before model',async()=>{
 const r=await worker.fetch(new Request('https://test/chat',{method:'POST',body:JSON.stringify({context:{profile:{age:30}}})}),env);assert.equal(r.status,403);
});
test('owner mismatch fails closed',async()=>{
 const r=await worker.fetch(new Request('https://test/chat',{method:'POST',body:'{}'}),{...env,ALLOWED_UIDS:'other'});assert.equal(r.status,503);
});
test('health advertises scope without persistent storage',async()=>{
 const r=await worker.fetch(new Request('https://test/health'),env);assert.equal((await r.json()).durableStorage,false);
});
test('malformed mixed scripts fail closed',()=>{assert.equal(outputSafe('يمكنك开始 بتحديد أوقاتك'),false);assert.equal(outputSafe('جرب تنظيم أوقات وجباتك بالطريقة اللي تناسبك'),true)});

test('malformed extended Latin fragment fails closed',()=>{assert.equal(outputSafe('استشارة chuyênي صحي'),false);assert.equal(outputSafe('جرب وجبة خفيفة لو جعان'),true)});

const bounded={question:'Explain my day',locale:'en',consentVersion:'coach-external-v1',context:{facts:[{key:'logged_energy',value:null,source:'diary',date:'2026-11-25',unit:'kcal'}],recentConversation:['user: variety']}};
test('bounded session summary retains unknown values and validates date units source',()=>{
 assert.equal(validateBoundedContext(bounded).context.facts[0].value,null);
 for(const patch of [{source:'meal:private-id'},{key:'uid'},{date:'2026-02-30'},{unit:'kg'},{value:-1},{value:'not known'}]) assert.throws(()=>validateBoundedContext({...bounded,context:{facts:[{...bounded.context.facts[0],...patch}]}}));
 for(const context of [{approvedMemories:[]},{uid:'private'},{facts:Array(7).fill(bounded.context.facts[0])}]) assert.throws(()=>validateBoundedContext({...bounded,context}));
});
test('bounded context health flag remains off by default',async()=>{
 let r=await worker.fetch(new Request('https://test/health'),env);assert.equal((await r.json()).scope,'typed-question-only');
 r=await worker.fetch(new Request('https://test/health'),{...env,BOUNDED_CONTEXT_ENABLED:'true'});assert.equal((await r.json()).scope,'bounded-session-context');
});
