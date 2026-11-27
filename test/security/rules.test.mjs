import fs from 'node:fs';
import assert from 'node:assert/strict';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, setDoc, getDoc, getDocs, collection, query, where} from 'firebase/firestore';

if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8089') {
  throw new Error('Refusing to test outside the local emulator at 127.0.0.1:8089');
}

let checks = 0;
async function run(rulesPath, projectId, proposed) {
  const env = await initializeTestEnvironment({projectId,
    firestore: {host: '127.0.0.1', port: 8089,
      rules: fs.readFileSync(rulesPath, 'utf8')}});
  try {
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      await setDoc(doc(db, 'recipes/draft'), {isPublished: false, title: 'Private draft fixture'});
      await setDoc(doc(db, 'recipes/published'), {isPublished: true, title: 'Published fixture'});
      await setDoc(doc(db, 'users/alice/meal_entries/m1'), {userId: 'alice', totalCalories: 200});
      await setDoc(doc(db, 'users/bob/meal_entries/m1'), {userId: 'bob', totalCalories: 300});
    });
    const anonymous = env.unauthenticatedContext().firestore();
    const alice = env.authenticatedContext('alice').firestore();
    await assertSucceeds(getDoc(doc(anonymous, 'recipes/published'))); checks++;
    const draftRead = getDoc(doc(anonymous, 'recipes/draft'));
    if (proposed) {
      await assertFails(draftRead); checks++;
      await assertFails(getDocs(collection(anonymous, 'recipes'))); checks++;
    } else {
      const result = await assertSucceeds(draftRead); checks++;
      assert.equal(result.data().isPublished, false);
      console.log('CONFIRMED: supplied original rules allow anonymous draft recipe reads.');
    }
    await assertSucceeds(getDocs(query(collection(anonymous, 'recipes'), where('isPublished', '==', true)))); checks++;
    await assertFails(setDoc(doc(anonymous, 'recipes/new'), {isPublished: true})); checks++;
    await assertFails(getDoc(doc(anonymous, 'users/alice/meal_entries/m1'))); checks++;
    await assertFails(getDoc(doc(alice, 'users/bob/meal_entries/m1'))); checks++;
    await assertFails(setDoc(doc(alice, 'users/bob/meal_entries/m2'), {userId: 'bob'})); checks++;
    await assertSucceeds(getDoc(doc(alice, 'users/alice/meal_entries/m1'))); checks++;
    await assertSucceeds(setDoc(doc(alice, 'users/alice/meal_entries/m2'), {userId: 'alice'})); checks++;
    await assertFails(setDoc(doc(alice, 'food_catalog/f1'), {name: 'Unauthorized catalog write'})); checks++;
    if (proposed) {
      const ownPaths = ['nutrition_profiles/main','meal_entries/m3','daily_logs/2026-11-23','weight_logs/w1','water_logs/w1','meal_plans/p1','shopping_lists/s1','shopping_lists/s1/items/i1','favorites/f1','notifications/n1','devices/d1','achievements/a1','conversations/c1','conversations/c1/messages/m1'];
      for (const path of ownPaths) {
        await assertSucceeds(setDoc(doc(alice, 'users/alice/'+path), {fixture:true})); checks++;
        await assertSucceeds(getDoc(doc(alice, 'users/alice/'+path))); checks++;
        await assertFails(getDoc(doc(anonymous, 'users/alice/'+path))); checks++;
        await assertFails(setDoc(doc(alice, 'users/bob/'+path), {fixture:true})); checks++;
        await assertFails(getDoc(doc(alice, 'users/bob/'+path))); checks++;
      }
      for (const path of ['food_catalog/f1','products/p1','food_categories/c1','recipes/published']) {
        await assertSucceeds(getDoc(doc(anonymous,path))); checks++;
        await assertFails(setDoc(doc(alice,path), {fixture:true})); checks++;
        await assertFails(setDoc(doc(anonymous,path), {fixture:true})); checks++;
      }
      for (const path of ['app_config/general','app_config/a/private/secret','unexpected/x','users/alice/unlisted/x']) {
        await assertFails(getDoc(doc(alice,path))); checks++;
        await assertFails(setDoc(doc(alice,path), {fixture:true})); checks++;
      }
      await assertFails(getDocs(collection(alice,'users'))); checks++;
    }
    console.log(`${proposed ? 'Proposed' : 'Original'} rule checks passed.`);
  } finally {
    await env.cleanup();
  }
}
await run('../../firestore.rules', 'demo-sufra-original', false);
await run('firestore.proposed.rules', 'demo-sufra-proposed', true);
console.log(`All ${checks} local Firestore rule assertions passed. No live Firebase project was contacted.`);
