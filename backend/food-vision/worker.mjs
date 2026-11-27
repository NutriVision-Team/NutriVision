import {gemmaVisionAnswer} from './gemma-recognition.mjs';
import {QWEN_MODEL,qwenNameRequest,qwenNameAnswer} from './qwen-recognition.mjs';
import {estimatedCandidates,ESTIMATE_PROMPT} from './estimate-contract.mjs';
import {createRemoteJWKSet,jwtVerify,importJWK} from 'jose';
const MODEL='@cf/moondream/moondream3.1-9B-A2B';
const keys=createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'));
const MAX=512*1024;
const json=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff'}});
export async function verifyUser(token,project,allowlist){
 if(!project||!allowlist)return null;
 const {payload,protectedHeader}=await jwtVerify(token,keys,{algorithms:['RS256'],issuer:`https://securetoken.google.com/${project}`,audience:project,requiredClaims:['exp','iat','sub','auth_time']});
 const now=Date.now()/1000;
 if(!protectedHeader.kid||!payload.sub||payload.sub.length>128||payload.iat>now||typeof payload.auth_time!=='number'||payload.auth_time>now||!(allowlist.trim()==='*'||allowlist.split(',').map(s=>s.trim()).includes(payload.sub)))return null;
 return payload.sub;
}
class OutputContractError extends Error {constructor(code){super(code);this.code=code;}}
export function candidates(raw){
 if(typeof raw?.answer!=='string')throw new OutputContractError('missing_answer');
 let answer=raw.answer.trim();
 // Accept one complete JSON code block, never extract JSON from arbitrary prose.
 const fenced=/^```(?:json)?\s*\n([\s\S]*?)\n```$/i.exec(answer);if(fenced)answer=fenced[1].trim();
 let value;try{value=JSON.parse(answer);}catch{throw new OutputContractError('answer_not_json');}
 if(!value||!Array.isArray(value.items)||value.items.length>12)throw new OutputContractError('items_shape');
 const items=value.items.map(i=>{if(!i||typeof i.name!=='string'||!i.name.trim()||i.name.length>160)throw new OutputContractError('item_name');return {name:i.name.trim(),confidence:null,suggestedPortionGrams:null,uncertaintyNotes:['Visual candidate only. Confirm ingredients and weighed portion.']};});
 return {requiresUserReview:true,items,generalNotes:['Image recognition cannot measure grams or provide verified nutrition.']};
}
const emptyResult=()=>({requiresUserReview:true,items:[],generalNotes:[]});
// The model answered but found no meal (empty, prose or no items list): a normal outcome, not a failure.
const noFood=e=>e instanceof SyntaxError||['items_absent','root_empty','root_array'].includes(e?.message);
async function qwenEstimate(env,encoded){
 const output=await env.AI.run('@cf/qwen/qwen3.8-27b',{messages:[{role:'user',content:[{type:'text',text:ESTIMATE_PROMPT},{type:'image_url',image_url:{url:'data:image/jpeg;base64,'+btoa(encoded)}}]}],max_completion_tokens:800,temperature:0,stream:false,store:false,reasoning_effort:'low',chat_template_kwargs:{enable_thinking:false},response_format:{type:'json_object'}});
 return estimatedCandidates({answer:output?.choices?.[0]?.message?.content});
}
export default{async fetch(request,env){
 const url=new URL(request.url);
 const origin=request.headers.get('origin');
 const allowedOrigin=origin&&/^http:\/\/(localhost|127\.0\.0\.1):[0-9]+$/.test(origin)?origin:null;
 if(request.method==='OPTIONS')return new Response(null,{status:allowedOrigin?204:403,headers:allowedOrigin?{'access-control-allow-origin':allowedOrigin,'access-control-allow-headers':'authorization,content-type','access-control-allow-methods':'POST,GET,OPTIONS','vary':'Origin'}:{}});
 const respond=(body,status=200)=>{const r=json(body,status);if(allowedOrigin){r.headers.set('access-control-allow-origin',allowedOrigin);r.headers.set('vary','Origin');}return r;};
 if(request.method==='GET'&&url.pathname==='/health')return respond({service:'sufra-food-vision',personalUploadsEnabled:env.ENABLED==='true'&&env.PERSONAL_UPLOADS_ENABLED==='true'});
 if(request.method!=='POST'||url.pathname!=='/recognize')return respond({error:'not_found'},404);
 // Personal input remains off until separately qualified and configured.
 if(env.ENABLED!=='true')return respond({error:'unavailable'},503);
 const bearer=request.headers.get('authorization')||'';if(!bearer.startsWith('Bearer ')||bearer.length>8192)return respond({error:'unauthorized'},401);
 let uid;let firebaseVerified=false;try{uid=await verifyUser(bearer.slice(7),env.FIREBASE_PROJECT_ID,env.ALLOWED_UIDS);firebaseVerified=!!uid;}catch{/* Qualification is independently signed, fixture-only, max10min. */}
 if(!uid&&env.QUALIFICATION_JWK){try{const key=await importJWK(JSON.parse(env.QUALIFICATION_JWK),'ES256');const {payload}=await jwtVerify(bearer.slice(7),key,{algorithms:['ES256'],issuer:'sufra-nonpersonal-qualification',audience:'sufra-food-vision',requiredClaims:['exp','iat','sub']});const now=Date.now()/1000;if(payload.sub==='synthetic-camera-test'&&typeof payload.exp==='number'&&typeof payload.iat==='number'&&payload.exp>payload.iat&&payload.exp-payload.iat<=600&&payload.iat<=now&&payload.fixture===env.APPROVED_FIXTURE_SHA256)uid='synthetic-camera-test';}catch{/* Reject. */}}
 if(!uid)return respond({error:'unauthorized'},401);
 if(!env.AI||!env.USER_LIMITER)return respond({error:'unavailable'},503);
 const {success}=await env.USER_LIMITER.limit({key:uid});if(!success)return respond({error:'rate_limited'},429);
 if(request.headers.get('content-type')!=='image/jpeg')return respond({error:'unsupported_image'},415);
 const declared=Number(request.headers.get('content-length'));if(request.headers.has('content-length')&&(!Number.isFinite(declared)||declared<=0||declared>MAX))return respond({error:'invalid_size'},413);
 let bytes;try{const reader=request.body.getReader();const parts=[];let n=0;for(;;){const {value,done}=await reader.read();if(done)break;n+=value.length;if(n>MAX){await reader.cancel();return respond({error:'invalid_size'},413);}parts.push(value);}bytes=new Uint8Array(n);let p=0;for(const b of parts){bytes.set(b,p);p+=b.length;}}catch{return respond({error:'invalid_image'},400);}
 if(bytes.length<4||bytes[0]!==255||bytes[1]!==216||bytes.at(-2)!==255||bytes.at(-1)!==217)return respond({error:'invalid_image'},400);
 // Qualification release accepts only the exact approved nonpersonal fixture.
 const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))).map(b=>b.toString(16).padStart(2,'0')).join('');
 if(!(firebaseVerified&&env.PERSONAL_UPLOADS_ENABLED==='true')&&(!env.APPROVED_FIXTURE_SHA256||hash!==env.APPROVED_FIXTURE_SHA256))return respond({error:'nonpersonal_test_only'},403);
 let encoded='';for(let i=0;i<bytes.length;i+=8192)encoded+=String.fromCharCode(...bytes.subarray(i,i+8192));
 if(env.VISION_MODEL==='gemma') {
  let raw=null;
  try {raw=await gemmaVisionAnswer(env.AI,'data:image/jpeg;base64,'+btoa(encoded),ESTIMATE_PROMPT);}catch{raw=null;}
  if(raw){
   try {return respond(estimatedCandidates(raw));}
   catch(error) {if(noFood(error))return respond(emptyResult());}
  }
  // Silent fallback: same Workers AI account, next model. A different provider is needed if the daily pool itself is empty.
  try {return respond(await qwenEstimate(env,encoded));}
  catch(error) {if(noFood(error))return respond(emptyResult());return respond({error:'inference_unavailable',stage:'all_models'},503);}
 }
 if(env.VISION_MODEL==='qwen'&&env.VISUAL_ESTIMATES_ENABLED!=='true') {
  try {
   const output=await env.AI.run(QWEN_MODEL,qwenNameRequest(btoa(encoded)));
   return respond(candidates(qwenNameAnswer(output)));
  } catch {return respond({error:'inference_unavailable',stage:'qwen_names_contract'},503);}
 }
 if(env.VISUAL_ESTIMATES_ENABLED==='true'&&env.VISION_MODEL==='qwen') {
  try {
   const output=await env.AI.run('@cf/qwen/qwen3.8-27b',{messages:[{role:'user',content:[{type:'text',text:ESTIMATE_PROMPT},{type:'image_url',image_url:{url:'data:image/jpeg;base64,'+btoa(encoded)}}]}],max_completion_tokens:800,temperature:0,stream:false,store:false,reasoning_effort:'low',chat_template_kwargs:{enable_thinking:false},response_format:{type:'json_object'}});
   const answer=output?.choices?.[0]?.message?.content;
   return respond(estimatedCandidates({answer}));
  }catch(error){return respond({error:'inference_unavailable',stage:'qwen_contract',failure:['invalid_food','invalid_portion','duplicate_food','missing_answer','items_absent','items_over_limit'].includes(error?.message)?error.message:'upstream_or_schema'},503);}
 }
 let stage='upstream';
 try{let output=await env.AI.run(MODEL,{task:'query',image:'data:image/jpeg;base64,'+btoa(encoded),question:env.VISUAL_ESTIMATES_ENABLED==='true'?ESTIMATE_PROMPT:'Identify visible foods only. Return JSON: {"items":[{"name":"food name"}]}. No nutrition, no weights, no identities, no medical advice. Empty items if no recognizable food.',reasoning:false,stream:true,max_tokens:env.VISUAL_ESTIMATES_ENABLED==='true'?512:384,temperature:0},{returnRawResponse:true});
 if(output instanceof Response){if(!output.ok||!output.body)return respond({error:'inference_unavailable',stage:'upstream_http',upstreamStatus:output.status},503);output=output.body;}
 stage='stream';
 let raw;if(output instanceof ReadableStream){const reader=output.getReader();const decoder=new TextDecoder();let text='';const deadline=Date.now()+40000;for(;;){let timer;const read=await Promise.race([reader.read(),new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error('timeout')),Math.max(1,deadline-Date.now()));})]).finally(()=>clearTimeout(timer));if(read.done)break;text+=decoder.decode(read.value,{stream:true});if(text.length>(env.VISUAL_ESTIMATES_ENABLED==='true'?2097152:262144)||Date.now()>deadline){await reader.cancel();throw Error('oversize_or_timeout');}}text+=decoder.decode();if(text.trimStart().startsWith('data:')){let answer='';let stopped=false;for(const line of text.split('\n')){if(!line.startsWith('data: '))continue;const data=line.slice(6);if(data==='[DONE]')continue;const event=JSON.parse(data);if(event.status==='failed')throw Error('model');if(typeof event.chunk?.answer==='string'){answer=event.chunk.answer;stopped=event.chunk.finish_reason==='stop';}}if(!stopped)throw Error('incomplete');raw={answer};}else{raw=JSON.parse(text);}}else{raw=output;}
 stage='output_schema';return respond(env.VISUAL_ESTIMATES_ENABLED==='true'?estimatedCandidates(raw):candidates(raw));}catch(error){return respond({error:'inference_unavailable',stage,...(error instanceof OutputContractError?{failure:error.code}:env.VISUAL_ESTIMATES_ENABLED==='true'?{failure:['model','incomplete','oversize_or_timeout','timeout','invalid_items','root_array','root_empty','items_absent','items_over_limit','invalid_food','invalid_portion','invalid_notes','duplicate_food'].includes(error?.message)?error.message:error instanceof SyntaxError?'response_json':'contract_or_stream'}:{})},503);}
}};
