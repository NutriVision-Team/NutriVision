import {createPublicKey,verify,X509Certificate} from 'node:crypto';
import {ProgressionError} from './engine.mjs';
const KEY_URL='https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
function reject(){throw new ProgressionError('invalid_identity');}
function decode(part){
 if(!/^[A-Za-z0-9_-]+$/.test(part)||part.length>12000)reject();
 try{return JSON.parse(Buffer.from(part,'base64url').toString('utf8'));}catch{reject();}
}
/** Node verifier, deliberately not claimed Workers-compatible or deployed. */
export function firebaseTokenVerifier({projectId,fetchKeys,clock=()=>Date.now()}){
 if(!/^[a-z][a-z0-9-]{4,62}$/.test(projectId))throw Error('invalid_project');
 let cache=null,expires=0,pending;
 const load=fetchKeys??(async()=>{
  const response=await fetch(KEY_URL,{signal:AbortSignal.timeout(5000)});
  if(!response.ok)throw Error('key_fetch_failed');
  const body=await response.text();if(body.length>100000)throw Error('key_payload_too_large');
  const ttl=Math.min(21600,Number(/max-age=(\d+)/.exec(response.headers.get('cache-control')??'')?.[1]??0));
  return {keys:JSON.parse(body),maxAgeSeconds:ttl};
 });
 return async token=>{
  if(typeof token!=='string'||token.length>16384)reject();
  const parts=token.split('.');if(parts.length!==3)reject();
  const h=decode(parts[0]),p=decode(parts[1]);
  if(h.alg!=='RS256'||typeof h.kid!=='string'||h.kid.length>256||!h.kid||h.crit||h.jku||h.x5u)reject();
  const now=Math.floor(clock()/1000);
  if(p.aud!==projectId||p.iss!==`https://securetoken.google.com/${projectId}`||typeof p.sub!=='string'||!p.sub||p.sub.length>128||p.sub.includes('/')||
    !Number.isInteger(p.exp)||p.exp<=now||!Number.isInteger(p.iat)||p.iat>now||!Number.isInteger(p.auth_time)||p.auth_time>now||p.auth_time<0||p.iat<0||p.exp<=p.iat)reject();
  if(!cache||clock()>=expires){
   pending??=load().finally(()=>{pending=null;});
   const data=await pending;
   if(!data.keys||typeof data.keys!=='object'||Object.keys(data.keys).length>10)reject();
   cache=data.keys;expires=clock()+Math.min(21600,Math.max(0,data.maxAgeSeconds))*1000;
  }
  // Unknown kid never forces repeated network fetches while cache is current.
  if(!Object.hasOwn(cache,h.kid))reject();
  const pem=cache[h.kid];if(typeof pem!=='string'||pem.length>20000)reject();
  let key;
  try{key=pem.includes('BEGIN CERTIFICATE')?new X509Certificate(pem).publicKey:createPublicKey(pem);}catch{reject();}
  if(key.asymmetricKeyType!=='rsa'||key.asymmetricKeyDetails.modulusLength<2048)reject();
  if(!/^[A-Za-z0-9_-]+$/.test(parts[2]))reject();
  if(!verify('RSA-SHA256',Buffer.from(`${parts[0]}.${parts[1]}`),key,Buffer.from(parts[2],'base64url')))reject();
  return {uid:p.sub,verified:true,authTime:p.auth_time};
 };
}
