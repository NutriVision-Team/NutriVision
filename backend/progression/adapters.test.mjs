import {test}from'node:test';
import assert from'node:assert/strict';
import{generateKeyPairSync,sign}from'node:crypto';
import{firebaseTokenVerifier}from'./firebase_token_verifier.mjs';
import{FirestoreRestStore,encodeFields,decodeFields}from'./firestore_rest_store.mjs';
const{publicKey,privateKey}=generateKeyPairSync('rsa',{modulusLength:2048});
const pub=publicKey.export({type:'spki',format:'pem'}),now=1806062400000;
function token(patch={},header={}){
 const h=Buffer.from(JSON.stringify({alg:'RS256',kid:'k1',...header})).toString('base64url');
 const p=Buffer.from(JSON.stringify({sub:'u',aud:'sufra-test',iss:'https://securetoken.google.com/sufra-test',iat:Math.floor(now/1000)-10,auth_time:Math.floor(now/1000)-20,exp:Math.floor(now/1000)+3600,...patch})).toString('base64url');
 return`${h}.${p}.${sign('RSA-SHA256',Buffer.from(`${h}.${p}`),privateKey).toString('base64url')}`;
}
function verifier(){let calls=0;const verify=firebaseTokenVerifier({projectId:'sufra-test',clock:()=>now,fetchKeys:async()=>{calls++;return{keys:{k1:pub},maxAgeSeconds:3600};}});return{verify,calls:()=>calls};}
test('real RSA verification plus cached public key',async()=>{const{verify,calls}=verifier();assert.deepEqual((await verify(token())).uid,'u');await verify(token());assert.equal(calls(),1);});
test('forged signature rejected',async()=>{const{verify}=verifier();const parts=token().split('.');parts[1]=Buffer.from(JSON.stringify({sub:'admin'})).toString('base64url');await assert.rejects(verify(parts.join('.')));});
test('issuer/audience/expiry/future auth/empty subject rejected',async()=>{for(const patch of[{iss:'https://evil.invalid'},{aud:'other'},{exp:1},{iat:Math.floor(now/1000)+1},{auth_time:Math.floor(now/1000)+1},{sub:''},{sub:'u/v'}]){const{verify}=verifier();await assert.rejects(verify(token(patch)));}});
test('algorithm confusion and external key URL rejected',async()=>{for(const header of[{alg:'none'},{alg:'HS256'},{jku:'https://evil.invalid'},{crit:['exp']}]){const{verify}=verifier();await assert.rejects(verify(token({},header)));}});
test('unknown kid does not force key-fetch storm',async()=>{const{verify,calls}=verifier();await verify(token());for(let i=0;i<10;i++)await assert.rejects(verify(token({},{kid:'unknown'})));assert.equal(calls(),1);});
test('key network failure fails closed',async()=>{const verify=firebaseTokenVerifier({projectId:'sufra-test',clock:()=>now,fetchKeys:async()=>{throw Error('unavailable');}});await assert.rejects(verify(token()),/unavailable/);});
test('Firestore codec is lossless for supported profile data',()=>{const data={a:1,b:true,c:['x',null],nested:{xp:100},decimal:.2};assert.deepEqual(decodeFields(encodeFields(data)),data);assert.throws(()=>decodeFields({x:{integerValue:'9999999999999999999999'}}));});
function transport({abort=false,fail=false}={}){
 const calls=[];let commits=0;
 const fetchImpl=async(url,options)=>{
  const body=options.body?JSON.parse(options.body):undefined;calls.push({url,options,body});
  let data={};let status=200;
  if(url.includes(':beginTransaction'))data={transaction:'dHgx'};
  else if(url.includes(':commit')){commits++;if(fail||abort&&commits===1){status=409;data={error:{status:fail?'PERMISSION_DENIED':'ABORTED'}};}}
  else if(url.endsWith(':batchGet'))data=[{found:{name:body.documents[0],fields:encodeFields({value:7,__serverCreateTime:'forged'}),createTime:'2026-11-24T11:00:00Z'}}];
  return new Response(JSON.stringify(data),{status});
 };
 return{calls,store:new FirestoreRestStore({projectId:'sufra-test',getAccessToken:async()=>'server-only-test-token',fetchImpl})};
}
test('REST reads join transaction, atomic create has exists:false',async()=>{const{store,calls}=transport();await store.runTransaction(async tx=>{const d=await tx.get('users/u');assert.equal(d.value,7);assert.equal(d.__serverCreateTime,'2026-11-24T11:00:00Z');await tx.create('users/u/gamification/profile',{xp:10});});const read=calls.find(c=>c.url.endsWith(':batchGet'));assert.equal(read.body.transaction,'dHgx');assert.deepEqual(read.body.documents,['projects/sufra-test/databases/(default)/documents/users/u']);const commit=calls.find(c=>c.url.endsWith(':commit'));assert.equal(commit.body.transaction,'dHgx');assert.equal(commit.body.writes[0].currentDocument.exists,false);});
test('ABORTED retries whole callback with bounded attempts',async()=>{const{store,calls}=transport({abort:true});let count=0;await store.runTransaction(async tx=>{count++;await tx.get('users/u');await tx.set('users/u',{xp:10});});assert.equal(count,2);assert.equal(calls.filter(c=>c.url.endsWith(':beginTransaction')).length,2);});
test('permission failure not retried and rollback attempted',async()=>{const{store,calls}=transport({fail:true});await assert.rejects(store.runTransaction(tx=>tx.create('users/u',{xp:10})));assert.equal(calls.filter(c=>c.url.endsWith(':beginTransaction')).length,1);assert(calls.some(c=>c.url.endsWith(':rollback')));});
test('read-only replay rolls back not commits',async()=>{const{store,calls}=transport();await store.runTransaction(tx=>tx.get('users/u'));assert(!calls.some(c=>c.url.endsWith(':commit')));assert(calls.some(c=>c.url.endsWith(':rollback')));});
test('path escape and read-after-write rejected',async()=>{const{store}=transport();assert.throws(()=>store.path('users/../secrets/x'));await assert.rejects(store.runTransaction(async tx=>{await tx.set('users/u',{});await tx.get('users/u');}),/read_after_write/);});
test('transaction batchGet missing result is explicit absence',async()=>{
 const calls=[];const store=new FirestoreRestStore({projectId:'sufra-test',getAccessToken:async()=>'test',fetchImpl:async(url,options)=>{
  const body=JSON.parse(options.body);calls.push({url,body});
  return Response.json(url.endsWith(':beginTransaction')?{transaction:'dHgx'}:url.endsWith(':batchGet')?[{missing:body.documents[0]}]:{});
 }});
 assert.equal(await store.runTransaction(tx=>tx.get('users/u')),undefined);
 assert.equal(calls.filter(c=>c.url.endsWith(':commit')).length,0);
 assert.equal(calls.filter(c=>c.url.endsWith(':rollback')).length,1);
});
test('malformed, wrong-document and ambiguous batchGet responses fail closed',async()=>{
 const name='projects/sufra-test/databases/(default)/documents/users/u';
 for(const result of [{},[],[{found:{name:'wrong'}}],[{missing:'wrong'}],[{found:{name},missing:name}],[{found:{name}},{missing:name}]]){
  let commits=0,rollbacks=0;
  const store=new FirestoreRestStore({projectId:'sufra-test',getAccessToken:async()=>'test',fetchImpl:async(url)=>{
   if(url.endsWith(':commit'))commits++;
   if(url.endsWith(':rollback'))rollbacks++;
   return Response.json(url.endsWith(':beginTransaction')?{transaction:'dHgx'}:url.endsWith(':batchGet')?result:{});
  }});
  await assert.rejects(store.runTransaction(async tx=>{await tx.get('users/u');await tx.set('users/u',{xp:999});}),/invalid_batch_get_response/);
  assert.equal(commits,0);assert.equal(rollbacks,1);
 }
});
test('permanent contention exhausts bounded retries without fake success',async()=>{
 let begins=0,commits=0;
 const store=new FirestoreRestStore({projectId:'sufra-test',maxAttempts:2,getAccessToken:async()=>'test',fetchImpl:async(url)=>{
  if(url.endsWith(':beginTransaction')){begins++;return Response.json({transaction:'dHgx'});}
  if(url.endsWith(':commit')){commits++;return Response.json({error:{status:'ABORTED'}},{status:409});}
  return Response.json({});
 }});
 await assert.rejects(store.runTransaction(tx=>tx.create('users/u',{xp:10})),/firestore_request_failed/);
 assert.equal(begins,2);assert.equal(commits,2);
});
