import test from 'node:test';import assert from 'node:assert/strict';import worker,{candidates,verifyUser}from './worker.mjs';
test('default deployment fails closed without inference',async()=>{let called=false;const r=await worker.fetch(new Request('https://test/recognize',{method:'POST'}),{AI:{run(){called=true;}}});assert.equal(r.status,503);assert.equal(called,false);});
test('no bearer, malformed or forged identity rejected before model',async()=>{for(const auth of ['', 'Bearer invalid.token.parts']){const r=await worker.fetch(new Request('https://test/recognize',{method:'POST',headers:{authorization:auth}}),{ENABLED:'true',FIREBASE_PROJECT_ID:'sufra-depi',ALLOWED_UIDS:'fixture'});assert.equal(r.status,401);}});
test('no arbitrary path, health reveals no identity/secrets',async()=>{assert.equal((await worker.fetch(new Request('https://test/no'),{})).status,404);const r=await worker.fetch(new Request('https://test/health'),{});assert.equal((await r.json()).personalUploadsEnabled,false);});
test('narrow output removes generated grams/calories/confidence',()=>{const v=candidates({answer:JSON.stringify({items:[{name:'Rice',calories:999,suggestedPortionGrams:600,confidence:.9}]})});assert.equal(v.items[0].confidence,null);assert.equal(v.items[0].suggestedPortionGrams,null);assert.equal(v.items[0].calories,undefined);assert.equal(v.requiresUserReview,true);assert.throws(()=>candidates({answer:'bad'}));assert.throws(()=>candidates({answer:'{"items":[{"name":""}]}'}));});
test('unconfigured project/allowlist rejects without keys',async()=>{assert.equal(await verifyUser('bad','',''),null);});
import {generateKeyPair,exportJWK,SignJWT}from 'jose';import {webcrypto}from 'node:crypto';
test('exact signed nonpersonal image invokes AI and cumulative SSE final answer only',async()=>{
 const bytes=new Uint8Array([255,216,0,1,255,217]);const hash=Array.from(new Uint8Array(await webcrypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
 const {privateKey,publicKey}=await generateKeyPair('ES256');const token=await new SignJWT({fixture:hash}).setProtectedHeader({alg:'ES256'}).setIssuer('sufra-nonpersonal-qualification').setAudience('sufra-food-vision').setSubject('synthetic-camera-test').setIssuedAt().setExpirationTime('10m').sign(privateKey);
 const env={ENABLED:'true',QUALIFICATION_JWK:JSON.stringify(await exportJWK(publicKey)),APPROVED_FIXTURE_SHA256:hash,USER_LIMITER:{limit:async()=>({success:true})},AI:{run:async(_model,_input,options)=>{assert.equal(options.returnRawResponse,true);assert.equal(options.rawResponse,undefined);return new Response(new ReadableStream({start(c){c.enqueue(new TextEncoder().encode('data: '+JSON.stringify({chunk:{answer:'{',finish_reason:''}})+'\n\ndata: '+JSON.stringify({chunk:{answer:'{"items":[{"name":"rice"}]}',finish_reason:'stop'}})+'\n\ndata: [DONE]\n\n'));c.close();}}),{headers:{'content-type':'text/event-stream'}});}}};
 const r=await worker.fetch(new Request('https://test/recognize',{method:'POST',headers:{authorization:'Bearer '+token,'content-type':'image/jpeg',origin:'http://127.0.0.1:8080'},body:bytes}),env);assert.equal(r.status,200);assert.equal((await r.json()).items[0].name,'rice');assert.equal(r.headers.get('access-control-allow-origin'),'http://127.0.0.1:8080');
 // Fixed diagnostic categories never return provider body or exception text.
 for(const [run,stage,status] of [
  [async()=>new Response('private upstream details',{status:429}),'upstream_http',429],
  [async()=>{throw Error('private provider exception');},'upstream',undefined],
  [async()=>new Response('data: {bad}\n\n'),'stream',undefined],
  [async()=>new Response(JSON.stringify({answer:'not json'})),'output_schema',undefined],
  [async()=>new Response('data: '+JSON.stringify({chunk:{answer:'{"items":[]}',finish_reason:''}})+'\n\n'),'stream',undefined],
 ]){
  env.AI.run=run;
  const fail=await worker.fetch(new Request('https://test/recognize',{method:'POST',headers:{authorization:'Bearer '+token,'content-type':'image/jpeg'},body:bytes}),env);
  assert.equal(fail.status,503);const body=await fail.json();assert.deepEqual(body,{error:'inference_unavailable',stage,...(status?{upstreamStatus:status}:{}),...(stage==='output_schema'?{failure:'answer_not_json'}:{})});
 }

});

test('complete JSON code fence normalized without arbitrary prose extraction',()=>{
 assert.equal(candidates({answer:'```json\n{"items":[{"name":"rice","calories":900}]}\n```'}).items[0].name,'rice');
 assert.deepEqual(candidates({answer:'```\n{"items":[]}\n```'}).items,[]);
 for(const answer of ['Here is JSON: {"items":[]}', '```json\n{"items":[]}\n``` extra', '```json\n{"items":[]}', '{"items":[{"name":""}]}'])assert.throws(()=>candidates({answer}));
});
test('output failures have fixed non-content categories',()=>{
 for(const [raw,code] of [[{},'missing_answer'],[{answer:'plain text'},'answer_not_json'],[{answer:'{}'},'items_shape'],[{answer:'{"items":[{}]}'},'item_name']])assert.throws(()=>candidates(raw),e=>e.code===code);
});

test('candidate bounds reject malformed or oversized names and item lists',()=>{
 for(const items of [null,{},Array.from({length:13},()=>({name:'rice'})),[{name:12}],[{name:'   '}],[{name:'x'.repeat(161)}]]) {
  assert.throws(()=>candidates({answer:JSON.stringify({items})}));
 }
 const result=candidates({answer:JSON.stringify({items:[{name:'  rice  ',instructions:'untrusted output',nutrition:{calories:200}}],extra:'not forwarded'})});
 assert.equal(result.items[0].name,'rice');
 assert.deepEqual(Object.keys(result.items[0]).sort(),['confidence','name','suggestedPortionGrams','uncertaintyNotes']);
 assert.equal(result.extra,undefined);
 assert.deepEqual(candidates({answer:'{"items":[]}'}).items,[]);
 assert.equal(candidates({answer:JSON.stringify({items:[{name:'x'.repeat(160)}]})}).items[0].name.length,160);
});

test('Qwen names-only branch preserves signed fixture/auth boundary and strips nutrition',async()=>{
 const bytes=new Uint8Array([255,216,0,1,255,217]);const hash=Array.from(new Uint8Array(await webcrypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
 const {privateKey,publicKey}=await generateKeyPair('ES256');const token=await new SignJWT({fixture:hash}).setProtectedHeader({alg:'ES256'}).setIssuer('sufra-nonpersonal-qualification').setAudience('sufra-food-vision').setSubject('synthetic-camera-test').setIssuedAt().setExpirationTime('10m').sign(privateKey);
 let calls=0;
 const env={ENABLED:'true',VISION_MODEL:'qwen',QUALIFICATION_JWK:JSON.stringify(await exportJWK(publicKey)),APPROVED_FIXTURE_SHA256:hash,USER_LIMITER:{limit:async()=>({success:true})},AI:{run:async(model,input)=>{calls++;assert.equal(model,'@cf/qwen/qwen3.8-27b');assert.equal(input.store,false);assert.equal(input.messages[0].content[1].image_url.url,'data:image/jpeg;base64,/9gAAf/Z');return {choices:[{finish_reason:'stop',message:{role:'assistant',content:'{"items":[{"name":"Rice","calories":999,"suggestedPortionGrams":777}]}'}}]};}}};
 const req=(body=bytes)=>new Request('https://test/recognize',{method:'POST',headers:{authorization:'Bearer '+token,'content-type':'image/jpeg'},body});
 const r=await worker.fetch(req(),env);assert.equal(r.status,200);const result=await r.json();assert.equal(result.items[0].name,'Rice');assert.equal(result.items[0].suggestedPortionGrams,null);assert.equal(result.items[0].calories,undefined);assert.equal(calls,1);
 assert.equal((await worker.fetch(req(new Uint8Array([255,216,2,3,255,217])),env)).status,403);assert.equal(calls,1);
 env.AI.run=async()=>({choices:[{finish_reason:'length',message:{role:'assistant',content:'{"items":[]}'}}]});assert.equal((await worker.fetch(req(),env)).status,503);
});

test('gemma failure silently falls back to qwen; both failing returns a plain 503',async()=>{
 const bytes=new Uint8Array([255,216,0,1,255,217]);const hash=Array.from(new Uint8Array(await webcrypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
 const {privateKey,publicKey}=await generateKeyPair('ES256');const token=await new SignJWT({fixture:hash}).setProtectedHeader({alg:'ES256'}).setIssuer('sufra-nonpersonal-qualification').setAudience('sufra-food-vision').setSubject('synthetic-camera-test').setIssuedAt().setExpirationTime('10m').sign(privateKey);
 const models=[];
 const env={ENABLED:'true',VISION_MODEL:'gemma',VISUAL_ESTIMATES_ENABLED:'true',QUALIFICATION_JWK:JSON.stringify(await exportJWK(publicKey)),APPROVED_FIXTURE_SHA256:hash,USER_LIMITER:{limit:async()=>({success:true})},AI:{run:async(model)=>{models.push(model);if(model.includes('gemma'))throw Error('daily limit');return {choices:[{finish_reason:'stop',message:{role:'assistant',content:'{"items":[{"name":"Rice","foodState":"cooked"}]}'}}]};}}};
 const req=()=>new Request('https://test/recognize',{method:'POST',headers:{authorization:'Bearer '+token,'content-type':'image/jpeg'},body:bytes});
 const r=await worker.fetch(req(),env);assert.equal(r.status,200);assert.equal((await r.json()).items[0].name,'rice'.replace('rice','Rice'));assert.equal(models.length,2);assert.match(models[1],/qwen/);
 env.AI.run=async()=>{throw Error('limit');};const f=await worker.fetch(req(),env);assert.equal(f.status,503);assert.equal((await f.json()).error,'inference_unavailable');
});

test('model answering with no meal returns an empty list, not an error; nameAr is passed only when Arabic',async()=>{
 const {estimatedCandidates}=await import('./estimate-contract.mjs');
 const r=estimatedCandidates({answer:JSON.stringify({items:[{name:'rice',nameAr:'رز',foodState:'cooked'},{name:'tea',nameAr:'<b>x</b>',foodState:'fluid'}]})});
 assert.equal(r.items[0].nameAr,'رز');assert.equal(r.items[1].nameAr,undefined);
 const bytes=new Uint8Array([255,216,0,1,255,217]);const hash=Array.from(new Uint8Array(await webcrypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
 const {privateKey,publicKey}=await generateKeyPair('ES256');const token=await new SignJWT({fixture:hash}).setProtectedHeader({alg:'ES256'}).setIssuer('sufra-nonpersonal-qualification').setAudience('sufra-food-vision').setSubject('synthetic-camera-test').setIssuedAt().setExpirationTime('10m').sign(privateKey);
 let n=0;const env={ENABLED:'true',VISION_MODEL:'gemma',VISUAL_ESTIMATES_ENABLED:'true',QUALIFICATION_JWK:JSON.stringify(await exportJWK(publicKey)),APPROVED_FIXTURE_SHA256:hash,USER_LIMITER:{limit:async()=>({success:true})},AI:{run:async()=>{n++;return {choices:[{finish_reason:'stop',message:{role:'assistant',content:'There is no food in this picture.'}}]};}}};
 const res=await worker.fetch(new Request('https://test/recognize',{method:'POST',headers:{authorization:'Bearer '+token,'content-type':'image/jpeg'},body:bytes}),env);
 assert.equal(res.status,200);assert.deepEqual((await res.json()).items,[]);assert.equal(n,1);
});
