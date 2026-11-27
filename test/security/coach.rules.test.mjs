import fs from 'node:fs';
import {initializeTestEnvironment,assertSucceeds,assertFails} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,deleteDoc,serverTimestamp} from 'firebase/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8089')throw Error('Local emulator only');
const env=await initializeTestEnvironment({projectId:'demo-sufra-coach',firestore:{rules:fs.readFileSync('firestore.coach.rules','utf8')}});
let n=0;
try{
 const a=env.authenticatedContext('a').firestore(),b=env.authenticatedContext('b').firestore(),anon=env.unauthenticatedContext().firestore();
 const cases=[['health_profile','current',{values:{allergens:['milk'],age:26}}],['coach_preferences','current',{fields:['allergens','habits']}],['health_goals','current',{goals:['food variety'],habits:['log_meal']}],['health_checkins','2026-11-24',{day:'2026-11-24',done:['log_meal']}]];
 for(const [c,id,v] of cases){
  const value={version:1,...v,updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(a,'users/a',c,id),value));n++;
  await assertSucceeds(getDoc(doc(a,'users/a',c,id)));n++;
  for(const db of [b,anon]){await assertFails(getDoc(doc(db,'users/a',c,id)));n++;await assertFails(setDoc(doc(db,'users/a',c,id),value));n++;}
  await assertFails(setDoc(doc(a,'users/a',c,id),{...value,rawChat:'forbidden'}));n++;
  await assertSucceeds(deleteDoc(doc(a,'users/a',c,id)));n++;
 }
 for(const values of [{age:0},{age:500},{heightCm:'tall'},{allergens:[5]},{allergens:Array(21).fill('x')},{specialistGuidance:'x'.repeat(501)},{unknown:'x'}]){await assertFails(setDoc(doc(a,'users/a/health_profile/current'),{version:1,values,updatedAt:serverTimestamp()}));n++;}
 await assertFails(setDoc(doc(a,'users/a/health_goals/current'),{version:1,goals:[],habits:['invented'],updatedAt:serverTimestamp()}));n++;
 await assertFails(setDoc(doc(a,'users/a/health_checkins/bad'),{version:1,day:'bad',done:[],updatedAt:serverTimestamp()}));n++;
 await assertFails(setDoc(doc(a,'users/a/health_profile/current'),{version:1,values:{},updatedAt:new Date(0)}));n++;
 await assertFails(setDoc(doc(a,'users/a/health_profile/other'),{version:1,values:{},updatedAt:serverTimestamp()}));n++;
 await assertFails(getDoc(doc(anon,'app_config/private')));n++;
 console.log('COACH_RULES_PASSED',n);
}finally{await env.cleanup();}
