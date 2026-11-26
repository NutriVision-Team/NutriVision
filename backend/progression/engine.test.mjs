import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {TrustedProgressionService} from './engine.mjs';
const config=JSON.parse(readFileSync(new URL('../../assets/data/progression.json',import.meta.url)));
// Serialized atomic fake proves service contract, not a Firestore integration.
class Store {
  constructor(){this.rows=new Map([['app_config/gamification',structuredClone(config)]]);this.tail=Promise.resolve();this.abort=false;}
  async runTransaction(fn){const previous=this.tail;let release;this.tail=new Promise(r=>release=r);await previous;
    const draft=structuredClone(this.rows);
    const tx={get:async p=>structuredClone(draft.get(p)),set:async(p,d)=>draft.set(p,structuredClone(d)),create:async(p,d)=>{assert(!draft.has(p));draft.set(p,structuredClone(d));}};
    try{const result=await fn(tx);if(this.abort)throw Error('commit_failed');this.rows=draft;return result;}finally{release();}
  }
}
const now=new Date('2026-11-24T12:00:00Z');
function setup(){const store=new Store();store.rows.set('users/u/meal_entries/m',{userId:'u',title:'Meal',dateKey:'2026-11-24',analysisStatus:'confirmed',__serverCreateTime:'2026-11-24T11:00:00Z'});const service=new TrustedProgressionService({store,clock:()=>now,verifyToken:async token=>token==='valid'?{uid:'u',verified:true}:null});return{store,service};}
test('concurrent duplicate requests create exactly one award',async()=>{const{store,service}=setup();const r=await Promise.all(Array.from({length:50},()=>service.award({token:'valid',kind:'meal',sourceId:'m'})));assert.equal(r.filter(x=>x.status==='awarded').length,1);assert.equal(store.rows.get('users/u/gamification/profile').totalXp,10);assert.equal(store.rows.size,5);});
test('different source ids cannot bypass per-day cap',async()=>{const{store,service}=setup();store.rows.set('users/u/meal_entries/n',store.rows.get('users/u/meal_entries/m'));await service.award({token:'valid',kind:'meal',sourceId:'m'});const r=await service.award({token:'valid',kind:'meal',sourceId:'n'});assert.equal(r.xp,0);});
test('forged uid/xp/day rejected',async()=>{const{service}=setup();for(const bad of [{uid:'v'},{xp:999},{day:'2026-11-01'}])await assert.rejects(service.award({token:'valid',kind:'meal',sourceId:'m',...bad}),/invalid_request/);});
test('unverified identity or token fails',async()=>{const{service}=setup();await assert.rejects(service.award({token:'forged',kind:'meal',sourceId:'m'}),/invalid_identity/);});
test('cross-account source cannot award',async()=>{const{store,service}=setup();store.rows.get('users/u/meal_entries/m').userId='v';await assert.rejects(service.award({token:'valid',kind:'meal',sourceId:'m'}),/ineligible_meal/);assert.equal(store.rows.size,2);});
test('missing source, pending and future time rejected',async()=>{for(const patch of [null,{analysisStatus:'pending'},{__serverCreateTime:'2026-11-25T11:00:00Z'}]){const{store,service}=setup();if(patch===null)store.rows.delete('users/u/meal_entries/m');else Object.assign(store.rows.get('users/u/meal_entries/m'),patch);await assert.rejects(service.award({token:'valid',kind:'meal',sourceId:'m'}));assert(!store.rows.has('users/u/gamification/profile'));}});
test('failed commit has no partial award or XP',async()=>{const{store,service}=setup();store.abort=true;await assert.rejects(service.award({token:'valid',kind:'meal',sourceId:'m'}),/commit_failed/);assert.equal(store.rows.size,2);store.abort=false;assert.equal((await service.award({token:'valid',kind:'meal',sourceId:'m'})).status,'awarded');});
test('version change cannot remint current bucket; new bucket needs migration',async()=>{const{store,service}=setup();await service.award({token:'valid',kind:'meal',sourceId:'m'});store.rows.get('app_config/gamification').version='rules-2';assert.equal((await service.award({token:'valid',kind:'meal',sourceId:'m'})).status,'already_awarded');store.rows.set('users/u',{uid:'u',onboardingCompleted:true});await assert.rejects(service.award({token:'valid',kind:'profile',sourceId:'setup'}),/config_migration_required/);});
test('unsupported health rewards and path injection rejected',async()=>{const{service}=setup();for(const [kind,sourceId]of[['weightLoss','m'],['meal','../other'],['recipe','r']])await assert.rejects(service.award({token:'valid',kind,sourceId}),/invalid_request/);});
test('profile XP once and not counted as eating/activity day',async()=>{const{store,service}=setup();store.rows.set('users/u',{uid:'u',onboardingCompleted:true});await service.award({token:'valid',kind:'profile',sourceId:'setup'});const p=store.rows.get('users/u/gamification/profile');assert.equal(p.totalXp,20);assert.equal(p.counts.activeDay,0);assert.deepEqual(p.earnedBadgeIds,['journey']);assert.equal((await service.award({token:'valid',kind:'profile',sourceId:'setup'})).xp,0);});

test('same source cannot be rewarded again on next server day',async()=>{
 const{store,service}=setup();await service.award({token:'valid',kind:'meal',sourceId:'m'});
 const tomorrow=new TrustedProgressionService({store,verifyToken:async()=>({uid:'u',verified:true}),clock:()=>new Date('2026-11-25T12:00:00Z')});
 const r=await tomorrow.award({token:'valid',kind:'meal',sourceId:'m'});
 assert.equal(r.status,'source_already_rewarded');assert.equal(store.rows.get('users/u/gamification/profile').totalXp,10);
});

test('client-created timestamp cannot replace server document metadata',async()=>{
 const{store,service}=setup();const m=store.rows.get('users/u/meal_entries/m');delete m.__serverCreateTime;m.createdAt='2026-11-24T11:00:00Z';
 await assert.rejects(service.award({token:'valid',kind:'meal',sourceId:'m'}),/ineligible_source_time/);
});

test('lifetime meal count grows while same-day XP stays capped',async()=>{
 const{store,service}=setup();
 for(let i=0;i<10;i++){const id='m'+i;store.rows.set('users/u/meal_entries/'+id,structuredClone(store.rows.get('users/u/meal_entries/m')));await service.award({token:'valid',kind:'meal',sourceId:id});}
 const p=store.rows.get('users/u/gamification/profile');assert.equal(p.totalXp,10);assert.equal(p.counts.meal,10);assert.equal(p.counts.activeDay,1);assert(p.earnedBadgeIds.includes('aware'));
});
