import fs from 'node:fs';
import assert from 'node:assert/strict';
import {initializeTestEnvironment,assertSucceeds,assertFails} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,writeBatch,deleteDoc,updateDoc,Timestamp,serverTimestamp} from 'firebase/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8089')throw Error('local_only');
const env=await initializeTestEnvironment({projectId:'demo-sufra-reward-policy',firestore:{host:'127.0.0.1',port:8089,rules:fs.readFileSync(new URL('./firestore.policy.rules',import.meta.url),'utf8')}});
const db=env.authenticatedContext('alice').firestore(),bob=env.authenticatedContext('bob').firestore();
const root='users/alice/reward_policy_proof/profile',ts=s=>Timestamp.fromDate(new Date(s));
let checks=0;
async function ok(name,fn){await fn();console.log('PASS',name);checks++;}
async function seed(path,data){await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),path),data));}
async function fixture(id,when,patch={}){await seed('users/alice/meal_entries/'+id,{userId:'alice',title:'Synthetic confirmed record',analysisStatus:'confirmed',rewardRecordedAt:ts(when),...patch});}
async function award(id,day,patch={},omit){const event='meal_'+id,marker=root+'/sources/'+event,bucket=root+'/days/'+day;const old=(await getDoc(doc(db,root))).data()??{xp:0,meals:0};const before=(await getDoc(doc(db,bucket))).data();const b=writeBatch(db);b.set(doc(db,root),{xp:old.xp+(before?0:10),meals:old.meals+1,lastEvent:event,zoneId:'Africa_Cairo',awardedAt:serverTimestamp(),...patch});if(omit!=='marker')b.set(doc(db,marker),{sourceId:id,dayKey:day,zoneId:'Africa_Cairo',awardedAt:serverTimestamp()});if(omit!=='bucket')b.set(doc(db,bucket),{count:(before?.count??0)+1,xp:10,lastEvent:event});return b.commit();}
try{
 await seed('reward_policy_proof/alice',{zoneId:'Africa_Cairo',activatedAt:ts('2026-01-01T00:00:00Z'),mealXp:10});
 for(const [day,start,end] of [['2026-04-24','2026-04-23T22:00:00Z','2026-04-24T21:00:00Z'],['2026-10-29','2026-10-28T21:00:00Z','2026-10-29T22:00:00Z'],['2026-11-21','2026-11-20T22:00:00Z','2026-11-21T22:00:00Z']])await seed('reward_calendar_proof/Africa_Cairo/days/'+day,{zoneId:'Africa_Cairo',dayKey:day,start:ts(start),end:ts(end)});
 await fixture('spring','2026-04-23T22:00:00Z');
 await ok('delayed recovery months later keeps original Cairo DST source day',()=>assertSucceeds(award('spring','2026-04-24')));
 await ok('duplicate/replay and direct bucket/profile reset denied',async()=>{await assertFails(award('spring','2026-04-24'));await assertFails(deleteDoc(doc(db,root)));await assertFails(deleteDoc(doc(db,root+'/days/2026-04-24')));});
 await fixture('fall','2026-10-29T21:30:00Z');
 await ok('25h Cairo fallback day accepted, source day not UTC date',()=>assertSucceeds(award('fall','2026-10-29')));
 await fixture('same','2026-04-24T20:59:59Z');
 await ok('out-of-order older same-day recovery counts record without second XP',async()=>{await assertSucceeds(award('same','2026-04-24'));const p=(await getDoc(doc(db,root))).data();assert.equal(p.xp,20);assert.equal(p.meals,3);});
 await fixture('boundary','2026-04-24T21:00:00Z');
 await ok('exclusive day-end boundary rejects previous local day',()=>assertFails(award('boundary','2026-04-24')));
 await fixture('legacy','2025-12-31T23:59:59Z');
 await ok('preactivation and missing recorded timestamp never backfill',async()=>{await assertFails(award('legacy','2026-04-24'));await seed('users/alice/meal_entries/missing',{userId:'alice',title:'Legacy',analysisStatus:'confirmed'});await assertFails(award('missing','2026-04-24'));});
 await fixture('new','2026-11-21T12:00:00Z');
 await ok('forged XP, timezone hopping, missing atomic parts denied',async()=>{await assertFails(award('new','2026-11-21',{xp:999}));await assertFails(award('new','2026-11-21',{zoneId:'UTC'}));await assertFails(award('new','2026-11-21',{},'marker'));await assertFails(award('new','2026-11-21',{},'bucket'));});
 await ok('trusted calendar and owner policy cannot be client-changed',async()=>{await assertFails(updateDoc(doc(db,'reward_policy_proof/alice'),{zoneId:'UTC'}));await assertFails(updateDoc(doc(db,'reward_calendar_proof/Africa_Cairo/days/2026-04-24'),{end:Timestamp.now()}));await assertFails(getDoc(doc(bob,root)));});
 await ok('accepted history survives ordinary source edit/delete and recreate cannot remint',async()=>{const before=(await getDoc(doc(db,root))).data();await assertSucceeds(updateDoc(doc(db,'users/alice/meal_entries/spring'),{title:'Ordinary edit'}));await assertSucceeds(deleteDoc(doc(db,'users/alice/meal_entries/spring')));const after=(await getDoc(doc(db,root))).data();assert.equal(after.xp,before.xp);assert.equal(after.meals,before.meals);await assertSucceeds(setDoc(doc(db,'users/alice/meal_entries/spring'),{userId:'alice',title:'Recreated',analysisStatus:'confirmed',rewardRecordedAt:serverTimestamp()}));await assertFails(award('spring','2026-04-24'));});
 console.log('TOTAL',checks,'policy Rules scenario groups. Isolated demo, no deploy or full progression integration.');
}finally{await env.cleanup();}
