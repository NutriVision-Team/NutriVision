import fs from 'node:fs';
import assert from 'node:assert/strict';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,writeBatch,Timestamp,serverTimestamp,deleteDoc,updateDoc} from 'firebase/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8089')throw Error('local_only');
const env=await initializeTestEnvironment({projectId:'demo-sufra-progression-app',firestore:{host:'127.0.0.1',port:8089,rules:fs.readFileSync(new URL('./firestore.account_day.rules',import.meta.url),'utf8')}});
const db=env.authenticatedContext('alice').firestore(),root='users/alice/gamification/profile';
const ts=s=>Timestamp.fromDate(new Date(s));
export const config={version:'accountday1',mealXp:10,planXp:20,profileXp:20,levelXp:[0,100,300,700,1500],levelIds:['beginner','explorer','organizer','balanced','ambassador'],badgeTargets:{journey:1,first_meal:1,aware:10,planner:1,planner3:3,returning:3,active7:7,active30:30}};
const seed=(p,d)=>env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),p),d));let count=0;
async function ok(name,fn){await fn();console.log('PASS',name);count++;}
async function fixture(kind,id,when){await seed(kind==='profile'?'users/alice':`users/alice/${kind==='meal'?'meal_entries':'meal_plans'}/${id}`,kind==='profile'?{uid:'alice',onboardingCompleted:true,rewardSetupRecordedAt:ts(when)}:kind==='meal'?{userId:'alice',title:'Synthetic',analysisStatus:'confirmed',rewardRecordedAt:ts(when)}:{status:'active',meals:[{}],startDate:ts('2026-11-16'),endDate:ts('2026-11-22'),rewardRecordedAt:ts(when)});}
async function award(kind,id,day,patch={}){
 const event=kind+'_'+id,p=(await getDoc(doc(db,root))).data()??{xp:0,meals:0,plans:0,setup:0,activeDays:0,lastActiveDay:ts('1970-01-01'),lastMealDay:ts('1970-01-01'),lastPlanDay:ts('1970-01-01')};
 const prior=(await getDoc(doc(db,root+'/days/'+day))).data(),setup=kind==='profile',meal=kind==='meal',plan=kind==='plan',label=ts(day);
 p.xp+=setup?20:prior?.[kind]?0:meal?10:20;if(meal)p.meals++;if(plan)p.plans++;if(setup)p.setup++;if(!setup&&!prior)p.activeDays++;
 if(!setup){if(label>p.lastActiveDay)p.lastActiveDay=label;const k=meal?'lastMealDay':'lastPlanDay';if(label>p[k])p[k]=label;}
 const metrics={journey:'setup',first_meal:'meals',aware:'meals',planner:'plans',planner3:'plans',returning:'activeDays',active7:'activeDays',active30:'activeDays'};
 Object.assign(p,{levelId:config.levelIds[config.levelXp.findLastIndex(x=>x<=p.xp)],badges:Object.fromEntries(Object.entries(metrics).map(([k,v])=>[k,p[v]>=config.badgeTargets[k]])),lastEvent:event,awardedAt:serverTimestamp(),configVersion:config.version,rewardZoneId:'Africa_Cairo'},patch);
 const b=writeBatch(db);b.set(doc(db,root),p);b.set(doc(db,root+'/sources/'+event),{kind,sourceId:id,dayKey:day,zoneId:'Africa_Cairo',awardedAt:serverTimestamp()});if(!setup)b.set(doc(db,root+'/days/'+day),{meal:prior?.meal??false,plan:prior?.plan??false,[kind]:true,lastEvent:event});return b.commit();
}
try{
 await seed('app_config/progression_proof',config);await seed('reward_policies/alice',{zone:'Africa/Cairo',zoneId:'Africa_Cairo',activatedAt:ts('2026-01-01')});
 for(const [day,start,end]of[['2026-04-24','2026-04-23T22:00Z','2026-04-24T21:00Z'],['2026-10-29','2026-10-28T21:00Z','2026-10-29T22:00Z'],['2026-11-21','2026-11-20T22:00Z','2026-11-21T22:00Z']])await seed('reward_calendars/Africa_Cairo/days/'+day,{zone:'Africa/Cairo',zoneId:'Africa_Cairo',dayKey:day,label:ts(day),start:ts(start),end:ts(end)});
 await fixture('profile','setup','2026-04-24T12:00Z');await ok('setup once full badge and level aggregate',()=>assertSucceeds(award('profile','setup','2026-04-24')));
 await fixture('meal','spring','2026-04-23T22:00Z');await ok('months delayed Cairo 23h source-day full transaction access budget',()=>assertSucceeds(award('meal','spring','2026-04-24')));
 await fixture('plan','weekly','2026-04-24T12:00Z');await ok('weekly plan same day separate kind allowance no extra active day',()=>assertSucceeds(award('plan','weekly','2026-04-24')));
 await fixture('meal','fall','2026-10-29T21:30Z');await ok('25h fallback full progression',()=>assertSucceeds(award('meal','fall','2026-10-29')));
 await fixture('meal','reverse','2026-04-24T20:00Z');await ok('reverse order keeps counters monotonic without repeated XP',async()=>{await assertSucceeds(award('meal','reverse','2026-04-24'));const p=(await getDoc(doc(db,root))).data();assert.equal(p.xp,60);assert.equal(p.activeDays,2);assert.equal(p.meals,3);assert.equal(p.badges.planner,true);});
 await ok('replay and forged aggregate denied',async()=>{await assertFails(award('meal','spring','2026-04-24'));await fixture('meal','forged','2026-11-21T12:00Z');await assertFails(award('meal','forged','2026-11-21',{xp:999}));});
 await ok('retained aggregate survives ordinary source edits and deletion',async()=>{await assertSucceeds(updateDoc(doc(db,'users/alice/meal_entries/spring'),{title:'Edit'}));await assertSucceeds(deleteDoc(doc(db,'users/alice/meal_entries/spring')));assert.equal((await getDoc(doc(db,root))).data().xp,60);await assertFails(deleteDoc(doc(db,root+'/days/2026-04-24')));await assertFails(deleteDoc(doc(db,root)));});
 await ok('old source no backfill and fixed zone cannot be client changed',async()=>{await fixture('meal','old','2025-12-31T12:00Z');await assertFails(award('meal','old','2026-11-21'));await assertFails(updateDoc(doc(db,'reward_policies/alice'),{zone:'UTC'}));});
 console.log('TOTAL',count,'integrated account-day Rules groups');
}finally{await env.cleanup();}
