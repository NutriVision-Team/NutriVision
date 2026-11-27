// Offline reference implementation. No deployment entrypoint or credentials.
const KINDS = new Set(['profile', 'meal', 'plan']);
const ID = /^[A-Za-z0-9_-]{1,128}$/;
export class ProgressionError extends Error {
  constructor(code) { super(code); this.code = code; }
}
// Explicit response masks reduce transport disclosure; they do NOT restrict IAM.
// Title and plan.meals remain necessary under the current eligibility contract.
export const PROGRESSION_MASKS=Object.freeze({
 config:Object.freeze(['schemaVersion','version','levels','badges','dailyXp']),
 ledger:Object.freeze(['uid','kind','bucket','xp']),
 marker:Object.freeze(['uid']),
 profileSource:Object.freeze(['uid','onboardingCompleted']),
 mealSource:Object.freeze(['userId','title','dateKey','analysisStatus']),
 planSource:Object.freeze(['meals','status']),
 profile:Object.freeze(['schemaVersion','uid','configVersion','totalXp','levelId','counts','earnedBadgeIds','lastActiveDay','currentStreak','bestStreak','updatedDay'])
});
const maskedGet=(tx,path,fields)=>tx.get(path,{fieldPaths:fields});
function assert(ok, code) { if (!ok) throw new ProgressionError(code); }
function validDate(value) {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    Number.isFinite(Date.parse(value)) && new Date(value).toISOString().slice(0,10) === value;
}
export function validateConfig(raw) {
  assert(raw?.schemaVersion === 1 && ID.test(raw.version), 'invalid_config');
  assert(Array.isArray(raw.levels) && raw.levels.length > 0 && raw.levels.length <= 20, 'invalid_levels');
  let previous = -1; const ids = new Set();
  for (const level of raw.levels) {
    assert(ID.test(level.id) && !ids.has(level.id) && Number.isSafeInteger(level.xp) && level.xp > previous && (previous !== -1 || level.xp === 0), 'invalid_levels');
    previous = level.xp; ids.add(level.id);
  }
  assert(Array.isArray(raw.badges) && raw.badges.length <= 32, 'invalid_badges');
  const badgeIds = new Set();
  for (const badge of raw.badges) {
    assert(ID.test(badge.id) && !badgeIds.has(badge.id) && ['profile','meal','plan','activeDay','recipe','lesson'].includes(badge.kind) && Number.isInteger(badge.target) && badge.target > 0 && badge.target < 100000, 'invalid_badges');
    badgeIds.add(badge.id);
  }
  assert(raw.dailyXp && typeof raw.dailyXp === 'object', 'invalid_xp');
  for (const kind of KINDS) {
    assert(Number.isInteger(raw.dailyXp[kind]) && raw.dailyXp[kind] >= 0 && raw.dailyXp[kind] <= 100, 'invalid_xp');
  }
  return structuredClone(raw);
}
function validateSource(kind, source, uid, id, now) {
  assert(source && typeof source === 'object', 'missing_source');
  if (kind === 'profile') {
    assert(id === 'setup' && source.uid === uid && source.onboardingCompleted === true, 'ineligible_profile');
    return;
  }
  if (kind === 'meal') {
    assert(source.userId === uid && source.title?.trim().length > 0 && validDate(source.dateKey) && source.analysisStatus === 'confirmed', 'ineligible_meal');
    // Source may be user entered. This verifies a recorded action, not ingestion.
  } else {
    assert(Array.isArray(source.meals) && source.meals.length > 0 && source.status === 'active', 'ineligible_plan');
  }
  // No retroactive/future XP backfill in v1. Processor uses its clock for awards.
  const created = Date.parse(source.__serverCreateTime);
  assert(Number.isFinite(created) && created <= now.getTime() && now.getTime()-created <= 48*3600000, 'ineligible_source_time');
}
function emptyProfile(uid, version, day) {
  return {schemaVersion:1,uid,configVersion:version,totalXp:0,levelId:null,
    counts:{profile:0,meal:0,plan:0,activeDay:0},earnedBadgeIds:[],
    lastActiveDay:null,currentStreak:0,bestStreak:0,updatedDay:day};
}
function validateStored(p, uid) {
  assert(p?.schemaVersion === 1 && p.uid === uid && Number.isSafeInteger(p.totalXp) && p.totalXp >= 0 && p.counts && typeof p.counts === 'object' && Array.isArray(p.earnedBadgeIds), 'corrupt_profile');
  for (const key of ['profile','meal','plan','activeDay']) assert(Number.isSafeInteger(p.counts[key]) && p.counts[key] >= 0, 'corrupt_profile');
  assert(p.earnedBadgeIds.every(x=>ID.test(x)) && Number.isSafeInteger(p.currentStreak) && p.currentStreak >= 0 && Number.isSafeInteger(p.bestStreak) && p.bestStreak >= p.currentStreak && (p.lastActiveDay === null || validDate(p.lastActiveDay)), 'corrupt_profile');
}

/**
 * Requires server-only adapters: verifyToken must cryptographically validate
 * audience/issuer/signature/expiry. store.runTransaction must atomically read
 * source/config/profile/ledger and create ledger+profile with conflict retries.
 * No client-supplied uid, xp, date, level or badge is accepted.
 */
export class TrustedProgressionService {
  constructor({verifyToken,store,clock=()=>new Date()}) {
    assert(typeof verifyToken === 'function' && typeof store?.runTransaction === 'function', 'missing_server_boundary');
    this.verifyToken=verifyToken;this.store=store;this.clock=clock;
  }
  async award({token,kind,sourceId,...extra}) {
    assert(Object.keys(extra).length === 0 && KINDS.has(kind) && ID.test(sourceId), 'invalid_request');
    assert(typeof token === 'string' && token.length > 0 && token.length < 16384, 'missing_auth');
    const identity = await this.verifyToken(token);
    assert(identity && ID.test(identity.uid) && identity.verified === true, 'invalid_identity');
    const uid=identity.uid,now=this.clock();
    assert(now instanceof Date && Number.isFinite(now.getTime()), 'invalid_clock');
    const day=now.toISOString().slice(0,10);
    const root=`users/${uid}/gamification/profile`;
    // Keys deliberately exclude config version and client source ID, so edits,
    // duplicate entities and config changes cannot remint the daily allowance.
    const bucket=kind==='profile'?'profile_once':`${kind}_${day}`;
    const ledgerPath=`${root}/transactions/${bucket}`;
    return this.store.runTransaction(async tx=>{
      const config=validateConfig(await maskedGet(tx,'app_config/gamification',PROGRESSION_MASKS.config));
      const existing=await maskedGet(tx,ledgerPath,PROGRESSION_MASKS.ledger);
      if (existing) {
        assert(existing.uid===uid && existing.kind===kind && existing.bucket===bucket && Number.isSafeInteger(existing.xp) && existing.xp>=0, 'corrupt_ledger');
      }
      const sourceMarker=`${root}/sources/${kind}_${sourceId}`;
      if (await maskedGet(tx,sourceMarker,PROGRESSION_MASKS.marker)) return {status:existing?'already_awarded':'source_already_rewarded',xp:0,bucket};
      const sourcePath=kind==='profile'?`users/${uid}`:`users/${uid}/${kind==='meal'?'meal_entries':'meal_plans'}/${sourceId}`;
      const source=await maskedGet(tx,sourcePath,PROGRESSION_MASKS[kind+'Source']);
      validateSource(kind,source,uid,sourceId,now);
      const previous=await maskedGet(tx,root,PROGRESSION_MASKS.profile);
      const profile=previous?structuredClone(previous):emptyProfile(uid,config.version,day);
      validateStored(profile,uid);
      // Config migration is explicit. Never recompute previously earned XP
      // under a new formula without a reviewed server-side migration.
      assert(profile.configVersion===config.version, 'config_migration_required');
      const xp=existing?0:config.dailyXp[kind];
      assert(Number.isSafeInteger(profile.totalXp+xp), 'xp_overflow');
      profile.totalXp+=xp;
      // Lifetime counts follow unique source records, separately from daily XP.
      profile.counts[kind]++;
      if (kind!=='profile' && profile.lastActiveDay!==day) {
        const gap=profile.lastActiveDay?Math.round((Date.parse(day)-Date.parse(profile.lastActiveDay))/86400000):null;
        assert(gap===null || gap>0, 'clock_regressed');
        profile.counts.activeDay++;
        profile.currentStreak=gap===1?profile.currentStreak+1:1;
        profile.bestStreak=Math.max(profile.bestStreak,profile.currentStreak);
        profile.lastActiveDay=day;
      }
      profile.levelId=config.levels.filter(l=>l.xp<=profile.totalXp).at(-1).id;
      const oldBadges=new Set(profile.earnedBadgeIds);
      const enabled=config.badges.filter(b=>b.kind==='activeDay' || KINDS.has(b.kind));
      const unlocks=enabled.filter(b=>(profile.counts[b.kind]??0)>=b.target&&!oldBadges.has(b.id)).map(b=>b.id);
      profile.earnedBadgeIds=[...oldBadges,...unlocks];
      profile.updatedDay=day;
      if (!existing) await tx.create(ledgerPath,{schemaVersion:1,uid,kind,sourceId,bucket,xp,
        configVersion:config.version,awardedAt:now.toISOString(),newBadgeIds:unlocks});
      await tx.create(sourceMarker,{schemaVersion:1,uid,kind,sourceId,bucket,xp,awardedAt:now.toISOString(),configVersion:config.version,newBadgeIds:unlocks});
      await tx.set(root,profile);
      return {status:existing?'activity_recorded':'awarded',xp,bucket,totalXp:profile.totalXp,levelId:profile.levelId,newBadgeIds:unlocks};
    });
  }
}
