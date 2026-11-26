import {test} from 'node:test';
import assert from 'node:assert/strict';
import {FirestoreRestStore,encodeFields} from './firestore_rest_store.mjs';
import {TrustedProgressionService,PROGRESSION_MASKS} from './engine.mjs';
import {readFileSync} from 'node:fs';
const config=JSON.parse(readFileSync(new URL('../../assets/data/progression.json',import.meta.url)));
const prefix='projects/demo-sufra-progression/databases/(default)/documents/';
test('meal award requests explicit source masks and omits unrelated health fields',async()=>{
 const docs=new Map([['app_config/gamification',config],['users/u/meal_entries/m',{userId:'u',title:'Meal',dateKey:'2026-11-24',analysisStatus:'confirmed',notes:'private sentinel',calories:999,photoUrl:'private photo',fullAnalysis:{medical:'private'}}]]);
 const reads=[];let commits=0;
 const store=new FirestoreRestStore({projectId:'demo-sufra-progression',getAccessToken:async()=>'synthetic',fetchImpl:async(url,options)=>{
  const body=JSON.parse(options.body);
  if(url.endsWith(':beginTransaction'))return Response.json({transaction:'dHg='});
  if(url.endsWith(':commit')){commits++;return Response.json({});}
  if(url.endsWith(':rollback'))return Response.json({});
  assert(url.endsWith(':batchGet'));const name=body.documents[0],path=name.slice(prefix.length);
  assert(Array.isArray(body.mask?.fieldPaths));reads.push({path,mask:body.mask.fieldPaths});
  const doc=docs.get(path);if(!doc)return Response.json([{missing:name}]);
  const fields=Object.fromEntries(body.mask.fieldPaths.filter(f=>Object.hasOwn(doc,f)).map(f=>[f,doc[f]]));
  assert(!JSON.stringify(fields).includes('private'));
  return Response.json([{found:{name,fields:encodeFields(fields),createTime:'2026-11-24T11:00:00Z'}}]);
 }});
 const service=new TrustedProgressionService({store,clock:()=>new Date('2026-11-24T12:00:00Z'),verifyToken:async()=>({uid:'u',verified:true})});
 assert.equal((await service.award({token:'synthetic',kind:'meal',sourceId:'m'})).xp,10);
 assert.equal(commits,1);assert.equal(reads.length,5);
 assert.deepEqual(reads.find(x=>x.path.includes('meal_entries')).mask,PROGRESSION_MASKS.mealSource);
});
test('malformed masks fail before document fetch or commit',async()=>{
 for(const fieldPaths of [[],['title','title'],['x/y'],['x..y'],['__bad;'],Array(33).fill('title'),'title']){
  let reads=0,commits=0;
  const store=new FirestoreRestStore({projectId:'demo-sufra-progression',getAccessToken:async()=>'synthetic',fetchImpl:async(url)=>{
   if(url.endsWith(':batchGet'))reads++;if(url.endsWith(':commit'))commits++;
   return Response.json(url.endsWith(':beginTransaction')?{transaction:'dHg='}:{});
  }});
  await assert.rejects(store.runTransaction(tx=>tx.get('users/u',{fieldPaths})),/invalid_field_mask/);
  assert.equal(reads,0);assert.equal(commits,0);
 }
});
test('masks do not pretend to remove current plan contents or title eligibility',()=>{
 assert(PROGRESSION_MASKS.planSource.includes('meals'));
 assert(PROGRESSION_MASKS.mealSource.includes('title'));
 assert.deepEqual(PROGRESSION_MASKS.profileSource,['uid','onboardingCompleted']);
});
