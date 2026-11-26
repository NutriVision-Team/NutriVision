import {createHandler,validateInput} from './coach.mjs';
import {verifyUser} from '../food-vision/worker.mjs';
const OWNER = 'iJbaLiTtlugbL9DUwVQikCy1A633';
// Deployment currently accepts typed questions only. A separate explicit
// deployment flag gates the reviewed bounded session-context contract.
const handler = createHandler({verify: verifyUser, preflight: () => null});
export default {async fetch(request, env) {
  const url = new URL(request.url);
  const origin = request.headers.get('origin');
  const cors = origin && /^http:\/\/(localhost|127\.0\.0\.1):[0-9]+$/.test(origin);
  const headers = cors ? {'access-control-allow-origin': origin, 'access-control-allow-headers': 'authorization,content-type', 'access-control-allow-methods': 'POST,GET,OPTIONS', 'vary': 'Origin'} : {};
  const json = (body, status=200) => new Response(JSON.stringify(body), {status, headers: {'content-type':'application/json','cache-control':'no-store',...headers}});
  if (request.method==='OPTIONS') return new Response(null, {status: cors?204:403, headers});
  if (request.method==='GET' && url.pathname==='/health') return json({service:'sufra-owner-coach', enabled:env.ENABLED==='true', scope:env.BOUNDED_CONTEXT_ENABLED==='true'?'bounded-session-context':'typed-question-only', durableStorage:false});
  if ((env.ALLOWED_UIDS!==OWNER && env.ALLOWED_UIDS!=='*') || env.FIREBASE_PROJECT_ID!=='sufra-depi') return json({error:'unavailable'},503);
  // Bounded clone parse before any model call; never log request contents.
  const declared = Number(request.headers.get('content-length'));
  if (declared>24000) return json({error:'invalid_request'},400);
  if (request.method==='POST' && url.pathname==='/chat') {
    try {
      const reader=request.clone().body.getReader();let size=0, text='';const decoder=new TextDecoder();
      for (;;) {const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>24000){await reader.cancel();return json({error:'invalid_request'},400);}text+=decoder.decode(value,{stream:true});}
      const body=JSON.parse(text+decoder.decode());
      if (!body.context || Object.keys(body.context).length!==0) {
        if (env.BOUNDED_CONTEXT_ENABLED!=='true') return json({error:'context_not_authorized'},403);
        try { validateBoundedContext(body); } catch { return json({error:'invalid_context'},400); }
      }
    } catch {return json({error:'invalid_request'},400);}
  }
  const response=await handler(request, env);
  const output=new Response(response.body,response);
  for(const [key,value] of Object.entries(headers)) output.headers.set(key,value);
  return output;
}};

// Date-key summary only. No stable record IDs, memory, writes or arbitrary keys.
export function validateBoundedContext(body) {
 validateInput(body); const c=body.context;
 if ('approvedMemories' in c) throw new Error('durable_memory_disabled');
 const expected={logged_energy:'kcal',logged_protein:'g',logged_carbohydrate:'g',logged_fat:'g',logged_fiber:'g',logged_water:'ml'};
 if(c.facts) {
  if(c.facts.length>6 || new Set(c.facts.map(f=>f.key)).size!==c.facts.length || new Set(c.facts.map(f=>f.date)).size>1) throw new Error('summary_limit');
  for(const f of c.facts) {
   if(!Object.hasOwn(expected,f.key)||expected[f.key]!==f.unit||f.source!==(f.key==='logged_water'?'water_log':'diary')||typeof f.date!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(f.date)||!Number.isFinite(Date.parse(f.date+'T00:00:00Z'))||new Date(f.date+'T00:00:00Z').toISOString().slice(0,10)!==f.date || (f.value!==null&&(!Number.isFinite(f.value)||f.value<0))) throw new Error('unapproved_summary');
  }
 }
 return body;
}
