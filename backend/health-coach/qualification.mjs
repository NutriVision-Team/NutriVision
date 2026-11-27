// Owner-authenticated fixed synthetic qualification only. No arbitrary prompts,
// personal data, storage or writes. Always fails closed after the test window.
import {verifyUser} from '../food-vision/worker.mjs';
import {MODEL,modelMessages,gemmaReplyContent,validateReply} from './coach.mjs';
import {reviewedCalculationInput,selectedCalculation,calculationContinuation} from './gemma-tools.mjs';
const OWNER='iJbaLiTtlugbL9DUwVQikCy1A633';
const END='2026-11-25T16:50:00Z';
const cases={
 ar_variety:{locale:'ar',question:'عندي عدس وخضار وعايز أغيّر أكلي، اقترح عليا فكرة بسيطة من غير أرقام تغذية.'},
 en_recipe:{locale:'en',question:'Suggest a simple way to use leftover cooked rice and vegetables, without numeric nutrition advice.'},
 chickpeas:{locale:'ar',question:'الحمص الناشف ينفع يتاكل بعد النقع بس من غير طبخ؟'},
};
export default {async fetch(request,env){
 const reply=(v,s=200)=>Response.json(v,{status:s,headers:{'cache-control':'no-store'}});
 if(env.QUALIFICATION_ENABLED!=='true'||!env.AI||!env.USER_LIMITER||Date.now()>Date.parse(END))return reply({error:'unavailable'},503);
 const url=new URL(request.url),id=url.pathname.slice(1);
 if(request.method!=='GET'||url.search||(!Object.hasOwn(cases,id)&&id!=='reviewed_tool'))return reply({error:'fixed_synthetic_only'},403);
 const bearer=request.headers.get('authorization')||'';
 try{if(!bearer.startsWith('Bearer ')||await verifyUser(bearer.slice(7),'sufra-depi',OWNER)!==OWNER)return reply({error:'unauthorized'},401);}catch{return reply({error:'unauthorized'},401);}
 if(!(await env.USER_LIMITER.limit({key:OWNER})).success)return reply({error:'rate_limited'},429);
 try{
  if(id==='reviewed_tool'){
   const reviewed={foodId:'synthetic-rice',name:'synthetic cooked rice fixture',grams:150};
   const input=reviewedCalculationInput('احسب طاقة الاختيار التجريبي اللي راجعته فقط. لا تحفظ أي سجل.',reviewed);
   const first=await env.AI.run(MODEL,input);
   const selected=selectedCalculation(first,reviewed);
   const result={...reviewed,energyKcal:195,proteinG:null,source:'SYNTHETIC TEST FIXTURE, NOT A FOOD RECORD',synthetic:true};
   const final=await env.AI.run(MODEL,calculationContinuation(input,first,reviewed,result));
   return reply({fixture:id,model:MODEL,selected,result,first,final});
  }
  const input={...cases[id],context:{},consentVersion:'coach-external-v1'};
  const output=await env.AI.run(MODEL,{messages:modelMessages(input),max_completion_tokens:1024,temperature:0.2,chat_template_kwargs:{enable_thinking:false},response_format:{type:'json_object'},store:false});
  let validation;try{validation={accepted:true,reply:validateReply(gemmaReplyContent(output))};}catch(e){validation={accepted:false,reason:e.message};}
  return reply({fixture:id,model:MODEL,output,validation});
 }catch(e){return reply({error:'synthetic_qualification_failed',reason:String(e.message).slice(0,120)},503);}
}};
