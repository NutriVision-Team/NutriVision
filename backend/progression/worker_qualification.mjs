// LOCAL QUALIFICATION HARNESS ONLY. No external fetch, deployed credentials or account API.
// Crypto flow prototype, not a production Firebase verifier/OAuth provider.
import {TrustedProgressionService} from './engine.mjs';
import {FirestoreRestStore,encodeFields} from './firestore_rest_store.mjs';
let fixture,publicKey,privateKey;
const te=new TextEncoder();
function bytes(s){return Uint8Array.from(atob(s.replace(/-/g,'+').replace(/_/g,'/')),c=>c.charCodeAt(0));}
const algo={name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'};
async function importKeys(){return Promise.all([crypto.subtle.importKey('jwk',fixture.publicJwk,algo,false,['verify']),crypto.subtle.importKey('pkcs8',bytes(fixture.privatePkcs8),algo,false,['sign'])]);}
async function verify(token,key){
 const [h,p,s]=token.split('.');const header=JSON.parse(atob(h)),claims=JSON.parse(atob(p));
 if(header.alg!=='RS256'||header.kid!=='synthetic'||claims.aud!=='demo-sufra-progression'||claims.sub!=='u'||claims.iss!=='https://securetoken.google.com/demo-sufra-progression'||claims.exp<=fixture.now/1000||!await crypto.subtle.verify(algo,key,bytes(s),te.encode(h+'.'+p)))throw Error('invalid_synthetic_token');
 return{uid:'u',verified:true};
}
export default {async fetch(request){
 const url=new URL(request.url);
 if(url.pathname==='/prepare'){
  fixture=await request.json();[publicKey,privateKey]=await importKeys();
  return Response.json({ready:true,syntheticOnly:true});
 }
 if(!fixture)return new Response('prepare required',{status:409});
 const mode=url.searchParams.get('mode')??'warm';
 let pub=publicKey,priv=privateKey;
 if(mode==='cold')[pub,priv]=await importKeys();
 if(mode==='cold'||mode==='refresh')await crypto.subtle.sign(algo,priv,te.encode(fixture.oauthAssertion));
 const identity=await verify(fixture.token,pub);
 if(url.pathname==='/forged'){
  try{await verify(fixture.token.slice(0,-5)+'AAAAA',pub);return new Response('forgery accepted',{status:500});}
  catch{return Response.json({rejected:true});}
 }
 const kind=url.searchParams.get('kind')??'meal';
 const source=kind==='profile'?{uid:'u',onboardingCompleted:true,healthDetails:'not transported'}:kind==='plan'?{meals:Array.from({length:100},()=>({title:'synthetic plan meal',calories:300})),status:'active',notes:'not transported'}:{userId:'u',title:'Synthetic meal',dateKey:'2026-11-24',analysisStatus:'confirmed',calories:300,photoUrl:'not transported',notes:'not transported'};
 const sourceId=kind==='profile'?'setup':'m';
 const path=kind==='profile'?'users/u':`users/u/${kind==='plan'?'meal_plans':'meal_entries'}/m`;
 const docs=new Map([['app_config/gamification',fixture.config],[path,source]]);
 let requests=0,commits=0;const disclosures=[];
 const store=new FirestoreRestStore({projectId:'demo-sufra-progression',getAccessToken:async()=>'synthetic-no-real-token',fetchImpl:async(url,options)=>{
  requests++;const body=JSON.parse(options.body);
  if(url.endsWith(':beginTransaction'))return Response.json({transaction:'dHg='});
  if(url.endsWith(':commit')){commits++;return Response.json({});}
  if(url.endsWith(':rollback'))return Response.json({});
  if(!url.endsWith(':batchGet'))throw Error('unexpected_outbound');
  const name=body.documents[0],path=name.split('/documents/')[1],doc=docs.get(path);
  if(!body.mask?.fieldPaths)throw Error('missing_mask');
  if(!doc)return Response.json([{missing:name}]);
  const fields=Object.fromEntries(body.mask.fieldPaths.filter(f=>Object.hasOwn(doc,f)).map(f=>[f,doc[f]]));
  disclosures.push(...Object.keys(fields));
  if(JSON.stringify(fields).includes('not transported'))throw Error('excess_disclosure');
  return Response.json([{found:{name,fields:encodeFields(fields),createTime:'2026-11-24T11:00:00Z'}}]);
 }});
 const service=new TrustedProgressionService({store,verifyToken:token=>verify(token,pub),clock:()=>new Date(fixture.now)});
 const result=await service.award({token:fixture.token,kind,sourceId});
 if(identity.uid!=='u'||commits!==1||requests!==7)throw Error('integration_assertion');
 return Response.json({result,requests,commits,disclosures,mode});
}};
