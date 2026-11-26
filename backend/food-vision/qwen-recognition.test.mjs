import test from 'node:test';import assert from 'node:assert/strict';
import {QWEN_MODEL,qwenNameRequest,qwenNameAnswer} from './qwen-recognition.mjs';
const out=(content,finish_reason='stop',extra={})=>({choices:[{finish_reason,message:{role:'assistant',content,...extra}}]});
test('candidate model input sends only fixed prompt and image, no identity or context',()=>{
 const req=qwenNameRequest('sample');assert.equal(QWEN_MODEL,'@cf/qwen/qwen3.8-27b');assert.equal(req.store,false);assert.equal(req.stream,false);assert.equal(req.messages.length,1);assert.equal(req.messages[0].content[1].image_url.url,'data:image/jpeg;base64,sample');assert.equal(req.max_completion_tokens,800);
});
test('drops generated nutrition, weights, instructions and unknown fields',()=>{
 const r=qwenNameAnswer(out(JSON.stringify({items:[{name:' Rice ',calories:999,suggestedPortionGrams:800,instruction:'not used'}],other:'not used'})));
 assert.deepEqual(JSON.parse(r.answer),{items:[{name:'Rice'}]});
});
test('rejects truncated, tool, reasoning-only and legacy outputs',()=>{
 for(const o of [out('{"items":[]}','length'),out(null),out('', 'stop',{reasoning_content:'not content'}),out('{"items":[]}','stop',{tool_calls:[{}]}),{response:'legacy'}, {choices:[]}])assert.throws(()=>qwenNameAnswer(o));
});
test('strict complete JSON, bounds, duplicates, empty abstention',()=>{
 assert.equal(qwenNameAnswer(out('```json\n{"items":[]}\n```')).answer,'{"items":[]}');
 for(const text of ['text {"items":[]}', '{}','{"items":{}}','{"items":[{"name":""}]}',JSON.stringify({items:Array.from({length:5},()=>({name:'x'}))}),JSON.stringify({items:[{name:'Rice'},{name:'rice'}]}),JSON.stringify({items:[{name:'x'.repeat(161)}]})])assert.throws(()=>qwenNameAnswer(out(text)));
});
