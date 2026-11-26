import catalog from '../../assets/data/foods.json' with {type:'json'};
const records = new Map(catalog.foods.map(f=>[f.id,f]));
export function calculateReviewed(selection) {
 if(!Array.isArray(selection)||!selection.length||selection.length>8)throw Error('invalid_selection');
 const ids=new Set();
 const portions=selection.map(p=>{
  if(!p||Object.keys(p).sort().join(',')!=='foodId,grams'||typeof p.foodId!=='string'||ids.has(p.foodId)||!Number.isFinite(p.grams)||p.grams<=0||p.grams>10000)throw Error('invalid_portion');
  ids.add(p.foodId);const f=records.get(p.foodId);if(!f||!Number.isFinite(f.nutrientsPer100g.energyKcal))throw Error('unknown_food');
  return {foodId:f.id,name:f.names.ar,state:f.foodState,grams:p.grams,source:f.source,nutrientsPer100g:f.nutrientsPer100g};
 });
 const sum=key=>portions.every(p=>Number.isFinite(p.nutrientsPer100g[key]))?portions.reduce((n,p)=>n+p.nutrientsPer100g[key]*p.grams/100,0):null;
 return {tool:'calculate_catalog_portions',catalogVersion:catalog.schemaVersion,portions,energyKcal:sum('energyKcal'),proteinG:sum('proteinG'),saved:false};
}
