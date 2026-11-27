import {FirestoreRestStore,encodeFields}from'./firestore_rest_store.mjs';
import{TrustedProgressionService}from'./engine.mjs';
import{readFileSync}from'node:fs';
import assert from'node:assert/strict';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8089')throw Error('local_emulator_required');
const projectId='demo-sufra-progression';
const origin='http://127.0.0.1:8089';
const store=new FirestoreRestStore({projectId,emulatorOrigin:origin,getAccessToken:async()=>'owner',maxAttempts:5});
async function seed(path,data){const r=await fetch(`${origin}/v1/projects/${projectId}/databases/(default)/documents/${path}`,{method:'PATCH',headers:{Authorization:'Bearer owner','Content-Type':'application/json'},body:JSON.stringify({fields:encodeFields(data)})});if(!r.ok)throw Error('seed_failed '+r.status);return r.json();}
const config=JSON.parse(readFileSync(new URL('../../assets/data/progression.json',import.meta.url)));
await seed('app_config/gamification',config);
for(let i=0;i<10;i++)await seed(`users/u/meal_entries/m${i}`,{userId:'u',title:'Recorded meal',dateKey:new Date().toISOString().slice(0,10),analysisStatus:'confirmed',createdAt:'1900-01-01T00:00:00Z',__serverCreateTime:'forged'});
const service=new TrustedProgressionService({store,verifyToken:async()=>({uid:'u',verified:true})});
// Real REST begin/read/commit against isolated local emulator. Identity is fake.
await Promise.all(Array.from({length:3},(_,i)=>service.award({token:'local-test',kind:'meal',sourceId:'m'+i})));
for(let i=3;i<10;i++)await service.award({token:'local-test',kind:'meal',sourceId:'m'+i});
const profile=await store.runTransaction(tx=>tx.get('users/u/gamification/profile'));
assert.equal(profile.totalXp,10);assert.equal(profile.counts.meal,10);assert.equal(profile.counts.activeDay,1);assert(profile.earnedBadgeIds.includes('aware'));
const results=await Promise.all(Array.from({length:10},()=>service.award({token:'local-test',kind:'meal',sourceId:'m0'})));
assert(results.every(r=>r.xp===0));
console.log('PASS: real local REST atomic contention,10unique sources,10duplicate replays,10XP total and correct lifetime counter.');
// Read back durable atomic state from a separate store instance, not callback output.
const independent=new FirestoreRestStore({projectId,emulatorOrigin:origin,getAccessToken:async()=>'owner'});
const after=await independent.runTransaction(tx=>tx.get('users/u/gamification/profile'));
assert.equal(after.totalXp,10);assert.equal(after.counts.meal,10);
let rewarded=0;
for(let i=0;i<10;i++){
 const marker=await independent.runTransaction(tx=>tx.get(`users/u/gamification/profile/sources/meal_m${i}`));
 assert.equal(marker.uid,'u');assert.equal(marker.sourceId,'m'+i);rewarded+=marker.xp;
}
assert.equal(rewarded,10);
const day=new Date().toISOString().slice(0,10);
const ledger=await independent.runTransaction(tx=>tx.get(`users/u/gamification/profile/transactions/meal_${day}`));
assert.equal(ledger.xp,10);assert.equal(ledger.uid,'u');
const before=JSON.stringify(after);
await assert.rejects(service.award({token:'local-test',kind:'meal',sourceId:'missing'}));
assert.equal(await independent.runTransaction(tx=>tx.get('users/u/gamification/profile/sources/meal_missing')),undefined);
const final=await independent.runTransaction(tx=>tx.get('users/u/gamification/profile'));
assert.equal(JSON.stringify(final),before);
assert.equal(await independent.runTransaction(tx=>tx.get('users/other/gamification/profile')),undefined);
console.log('PASS: independent durable profile/ledger/10 source markers, summed marker XP, replay stability, absent-source rollback and untouched other owner.');
// Local request contract integration. No HTTP listener or deployed endpoint.
const {localLedgerContract}=await import('./local_contract.mjs');
const policy={status:'provisional',dayBasis:'UTC',retention:'unresolved'};
const handler=localLedgerContract({service,store:independent,verifyToken:async token=>token==='local-test'?{uid:'u',verified:true}:null,policy});
assert.equal((await handler({method:'GET',path:'/v1/profile'})).status,401);
assert.equal((await handler({method:'GET',path:'/v1/profile',authorization:'Bearer invalid'})).status,401);
assert.equal((await handler({method:'POST',path:'/v1/award',authorization:'Bearer local-test',body:{kind:'meal',sourceId:'m0',uid:'other',xp:999}})).status,400);
assert.equal((await handler({method:'POST',path:'/v1/award',authorization:'Bearer local-test',body:{kind:'meal',sourceId:'m0'}})).body.result.xp,0);
const envelope=await handler({method:'GET',path:'/v1/profile',authorization:'Bearer local-test'});
assert.equal(envelope.status,200);assert.equal(envelope.body.profile.totalXp,10);
const failed=localLedgerContract({service,store:{runTransaction:async()=>{throw Error('private transport detail');}},verifyToken:async()=>({uid:'u',verified:true}),policy});
assert.deepEqual(await failed({method:'GET',path:'/v1/profile',authorization:'Bearer local-test'}),{status:503,body:{error:'ledger_unavailable'}});
const{writeFileSync}=await import('node:fs');
writeFileSync('/downloads/sufra/trusted_ledger_emulator_envelope1023.json',JSON.stringify(envelope.body));
console.log('PASS: local request contract auth/forged fields/replay/server-read/outage redaction; safe synthetic profile envelope saved for Dart adapter integration.');
