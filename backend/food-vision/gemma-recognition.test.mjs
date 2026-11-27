import test from 'node:test';import assert from 'node:assert/strict';
import {gemmaVisionAnswer,GEMMA_VISION_MODEL} from './gemma-recognition.mjs';
test('qualified Gemma request keeps fixed image-only contract and no storage',async()=>{
 const answer=await gemmaVisionAnswer({run:async(model,input)=>{assert.equal(model,GEMMA_VISION_MODEL);assert.equal(input.store,false);assert.equal(input.stream,false);assert.equal(input.messages[0].content[1].image_url.url,'data:image/jpeg;base64,fixture');return {choices:[{finish_reason:'stop',message:{content:'{"items":[]}'}}]};}},'data:image/jpeg;base64,fixture','fixed prompt');assert.equal(answer.answer,'{"items":[]}');
});
test('Gemma rejects incomplete and malformed responses',async()=>{for(const output of [{}, {choices:[]},{choices:[{finish_reason:'length',message:{content:'{}'}}]},{choices:[{finish_reason:'stop',message:{}}]}])await assert.rejects(gemmaVisionAnswer({run:async()=>output},'image','fixed'));});
