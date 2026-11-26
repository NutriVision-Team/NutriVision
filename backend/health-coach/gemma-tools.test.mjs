import test from 'node:test';
import assert from 'node:assert/strict';
import {reviewedCalculationInput,selectedCalculation,calculationContinuation} from './gemma-tools.mjs';
const selection={foodId:'synthetic-selected-food',name:'Synthetic catalog food',grams:150};
const output={choices:[{finish_reason:'tool_calls',message:{role:'assistant',content:null,tool_calls:[{id:'synthetic-call-1',type:'function',function:{name:'calculate_catalog_portions',arguments:JSON.stringify({foodId:selection.foodId,grams:150})}}]}}]};
const result={...selection,energyKcal:150,proteinG:null,source:'synthetic-test-only',synthetic:true};
test('explicit reviewed mapping is separate from allowed argument enum',()=>{
 const input=reviewedCalculationInput('Calculate reviewed food',selection);
 assert.deepEqual(JSON.parse(input.messages[1].content).reviewedSelection,selection);
 assert.equal(input.tools[0].function.parameters.properties.foodId.enum[0],selection.foodId);
 assert.equal(input.tool_choice,'auto');
 assert.throws(()=>reviewedCalculationInput('x',null));
});
test('tool calls require exact reviewed arguments and one known read-only tool',()=>{
 assert.equal(selectedCalculation(output,selection).grams,150);
 for(const altered of [{...selection,grams:151},{...selection,foodId:'other'}])assert.throws(()=>selectedCalculation(output,altered));
 const extra=structuredClone(output);extra.choices[0].message.tool_calls[0].function.arguments=JSON.stringify({...selection,sql:'query'});assert.throws(()=>selectedCalculation(extra,selection));
 const wrong=structuredClone(output);wrong.choices[0].message.tool_calls[0].function.name='save';assert.throws(()=>selectedCalculation(wrong,selection));
 const noCall={choices:[{finish_reason:'stop',message:{role:'assistant',content:'Please review food'}}]};assert.throws(()=>selectedCalculation(noCall,selection));
});
test('real assistant/tool message linkage uses provider call id, unknown stays null',()=>{
 const next=calculationContinuation(reviewedCalculationInput('x',selection),output,selection,result);
 assert.equal(next.messages[2].role,'assistant');assert.equal(next.messages[3].role,'tool');
 assert.equal(next.messages[3].tool_call_id,'synthetic-call-1');
 assert.equal(JSON.parse(next.messages[3].content).proteinG,null);assert.equal(next.tool_choice,'none');
 for(const bad of [{...result,grams:200},{...result,synthetic:false},{...result,energyKcal:NaN}])assert.throws(()=>calculationContinuation(reviewedCalculationInput('x',selection),output,selection,bad));
});
