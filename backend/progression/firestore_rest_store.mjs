// Transport adapter for Firestore REST, no credentials/deployments included.
// getAccessToken must supply a server-only OAuth token with minimum IAM scope.
import {ProgressionError} from './engine.mjs';
export function encodeValue(v){
 if(v===null)return{nullValue:null};
 if(typeof v==='boolean')return{booleanValue:v};
 if(typeof v==='string')return{stringValue:v};
 if(Number.isSafeInteger(v))return{integerValue:String(v)};
 if(typeof v==='number'&&Number.isFinite(v))return{doubleValue:v};
 if(Array.isArray(v))return{arrayValue:{values:v.map(encodeValue)}};
 if(v&&Object.getPrototypeOf(v)===Object.prototype)return{mapValue:{fields:encodeFields(v)}};
 throw new ProgressionError('unsupported_firestore_value');
}
export const encodeFields=o=>Object.fromEntries(Object.entries(o).map(([k,v])=>[k,encodeValue(v)]));
export function decodeValue(v){
 if('nullValue'in v)return null;
 if('stringValue'in v)return v.stringValue;
 if('timestampValue'in v)return v.timestampValue;
 if('booleanValue'in v)return v.booleanValue;
 if('integerValue'in v){const n=Number(v.integerValue);if(!Number.isSafeInteger(n))throw Error('unsafe_firestore_integer');return n;}
 if('doubleValue'in v){if(!Number.isFinite(v.doubleValue))throw Error('invalid_firestore_number');return v.doubleValue;}
 if('arrayValue'in v)return(v.arrayValue.values??[]).map(decodeValue);
 if('mapValue'in v)return decodeFields(v.mapValue.fields??{});
 throw Error('unsupported_firestore_type');
}
export const decodeFields=o=>Object.fromEntries(Object.entries(o).map(([k,v])=>[k,decodeValue(v)]));
export class FirestoreRestStore{
 constructor({projectId,database='(default)',getAccessToken,fetchImpl=fetch,maxAttempts=3,emulatorOrigin}){
  if(!/^[a-z][a-z0-9-]{4,62}$/.test(projectId)||!/^\(default\)$|^[a-z][a-z0-9-]{2,62}$/.test(database)||typeof getAccessToken!=='function'||!Number.isInteger(maxAttempts)||maxAttempts<1||maxAttempts>5)throw Error('invalid_store_config');
  this.base=`https://firestore.googleapis.com/v1/projects/${projectId}/databases/${database}/documents`;this.documentPrefix=`projects/${projectId}/databases/${database}/documents/`;
  if(emulatorOrigin){if(!/^http:\/\/127\.0\.0\.1:[0-9]{4,5}$/.test(emulatorOrigin)||!projectId.startsWith('demo-'))throw Error('unsafe_emulator_target');this.base=emulatorOrigin+'/v1/'+this.documentPrefix.slice(0,-1);}
  this.getAccessToken=getAccessToken;this.fetch=fetchImpl;this.maxAttempts=maxAttempts;
 }
 path(path){if(typeof path!=='string'||path.length>1200||path.split('/').length%2!==0||path.split('/').some(x=>!x||x==='.'||x==='..'||!/^[-A-Za-z0-9_]+$/.test(x)))throw Error('invalid_document_path');return path;}
 async request(suffix,{method='POST',body,allowMissing=false}={}){
  const token=await this.getAccessToken();if(typeof token!=='string'||!token)throw Error('missing_server_token');
  const r=await this.fetch(this.base+suffix,{method,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(30000)});
  if(allowMissing&&r.status===404)return null;
  const text=await r.text();if(text.length>2000000)throw Error('firestore_payload_too_large');
  const data=text?JSON.parse(text):{};
  if(!r.ok){const e=new Error('firestore_request_failed');e.status=data.error?.status;e.httpStatus=r.status;throw e;}
  return data;
 }
 async runTransaction(fn){
  for(let attempt=0;attempt<this.maxAttempts;attempt++){
   const begin=await this.request(':beginTransaction',{body:{options:{readWrite:{}}}});
   if(typeof begin.transaction!=='string'||!begin.transaction)throw Error('missing_transaction_id');
   const id=begin.transaction,writes=[];let writing=false;
   const tx={get:async (path,{fieldPaths}={})=>{
    if(writing)throw Error('read_after_write');
    path=this.path(path);const name=this.documentPrefix+path;
    if(fieldPaths!==undefined&&(!Array.isArray(fieldPaths)||fieldPaths.length===0||fieldPaths.length>32||new Set(fieldPaths).size!==fieldPaths.length||fieldPaths.some(x=>typeof x!=='string'||!/^[_A-Za-z][_A-Za-z0-9]*(\.[_A-Za-z][_A-Za-z0-9]*)*$/.test(x))))throw Error('invalid_field_mask');
    // JSON-body transaction bytes avoid the emulator GET query transcoder's
    // BYTE_STRING failure. batchGet is also a documented production REST API.
    const stream=await this.request(':batchGet',{body:{documents:[name],transaction:id,...(fieldPaths?{mask:{fieldPaths}}:{})}});
    if(!Array.isArray(stream))throw Error('invalid_batch_get_response');
    const rows=stream.filter(row=>row.found||row.missing);
    if(rows.length!==1)throw Error('invalid_batch_get_response');
    const row=rows[0];
    if(row.missing===name&&!row.found)return undefined;
    const d=row.found;
    if(!d||d.name!==name||row.missing)throw Error('invalid_batch_get_response');
    return{...decodeFields(d.fields??{}),__serverCreateTime:d.createTime};
   },
    create:async(path,data)=>{writing=true;writes.push({update:{name:this.documentPrefix+this.path(path),fields:encodeFields(data)},currentDocument:{exists:false}});},
    set:async(path,data)=>{writing=true;writes.push({update:{name:this.documentPrefix+this.path(path),fields:encodeFields(data)}});}};
   try{
    const result=await fn(tx);
    if(writes.length>10)throw Error('too_many_award_writes');
    if(writes.length)await this.request(':commit',{body:{transaction:id,writes}});
    else await this.request(':rollback',{body:{transaction:id}});
    return result;
   }catch(error){
    try{await this.request(':rollback',{body:{transaction:id}});}catch{}
    if(error.status==='ABORTED'&&attempt+1<this.maxAttempts){await new Promise(r=>setTimeout(r,50*(attempt+1)+Math.random()*100));continue;}
    throw error;
   }
  }
 }
}
