// Opt-in candidate contract. Nutrition is never accepted from model output.
// Visual grams are uncertain suggestions that the app must label and confirm.
export const ESTIMATE_PROMPT = "Analyze the visible meal, not a catalog. Identify foods as they actually appear. Use ordinary English food names, not database record names. Distinguish cooked food from raw ingredients; use unknown for preparation you cannot see. Consider Egyptian and other cuisines but never assume a cuisine. For a named mixed prepared dish use foodState prepared and return the dish once, not both the dish and its ingredients. A separate side or bread may be another item. If you cannot identify a dish, describe the visible components instead, never invent a specific dish. Do not identify a bean variety or meat cut unless visually clear. Do not invent hidden oil, sugar, meat or garnish. A grocery display, raw ingredient collection or nonfood scene is not a plated meal: return an empty items array. Return JSON only: {\"items\":[{\"name\":\"ordinary English food or dish name\",\"nameAr\":\"the same food in simple Arabic\",\"foodState\":\"raw|cooked|dried|prepared|fluid|canned|unknown\",\"suggestedPortionGrams\":null}]}. At most four distinct foods. suggestedPortionGrams may be a rough visual estimate only when the portion is visible; otherwise null. It is a suggestion, never a measurement. No calories, macros, confidence scores or database IDs.";
const states=new Set(['raw','cooked','dried','prepared','fluid','canned','unknown']);
function notes(value,max) {
 if(value===undefined)return [];
 if(!Array.isArray(value)||value.length>max||value.some(x=>typeof x!=='string'||!x.trim()||x.length>500))throw Error('invalid_notes');
 return value.map(x=>x.trim());
}
export function estimatedCandidates(raw) {
 if(typeof raw?.answer!=='string'||raw.answer.length>65536)throw Error('missing_answer');
 let answer=raw.answer.trim();const fence=/^```(?:json)?\s*\n([\s\S]*?)\n```$/i.exec(answer);if(fence)answer=fence[1].trim();
 const decoded=JSON.parse(answer);
 const v=Array.isArray(decoded)?{items:decoded}:decoded;
 if(!v||!Array.isArray(v.items)||v.items.length>12)throw Error(Array.isArray(v)?'root_array':!v?'root_empty':!Array.isArray(v.items)?'items_absent':'items_over_limit');
 const seen=new Set();
 const items=v.items.map(x=>{
  if(!x||typeof x.name!=='string'||!x.name.trim()||x.name.length>160||!states.has(x.foodState))throw Error('invalid_food');
  const identity=x.name.trim().toLowerCase();if(seen.has(identity))throw Error('duplicate_food');seen.add(identity);
  const grams=x.suggestedPortionGrams===undefined?null:x.suggestedPortionGrams;
  if(grams!==null&&(typeof grams!=='number'||!Number.isFinite(grams)||grams<=0||grams>3000))throw Error('invalid_portion');
  const nameAr=typeof x.nameAr==='string'&&x.nameAr.trim().length>0&&x.nameAr.length<=160&&/[\u0600-\u06FF]/.test(x.nameAr)&&!/[<>{}\[\]]/.test(x.nameAr)?x.nameAr.trim():undefined;
  return {name:x.name.trim(),...(nameAr?{nameAr}:{}),foodState:x.foodState,suggestedPortionGrams:grams,confidence:null,uncertaintyNotes:[...notes(x.uncertaintyNotes,10),'Visual estimate, not a measured amount. Review food, preparation and grams.']};
 });
 return {requiresUserReview:true,items,generalNotes:[...notes(v.generalNotes,10),'Hidden oil, sugar and ingredients may be missing. Nutrition must come from a matched sourced food record, not the model.']};
}
