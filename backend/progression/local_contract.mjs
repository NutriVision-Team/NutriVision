// Local integration contract only. No listener, deployment entrypoint or credentials.
import {ProgressionError} from './engine.mjs';
const ID=/^[A-Za-z0-9_-]{1,128}$/;
export function localLedgerContract({service,store,verifyToken,policy}){
 if(policy?.status!=='provisional'||policy.dayBasis!=='UTC'||policy.retention!=='unresolved')throw Error('explicit_provisional_policy_required');
 return async({method,path,authorization,body})=>{
  try{
   if(!authorization?.startsWith('Bearer '))return{status:401,body:{error:'authentication_required'}};
   const token=authorization.slice(7);
   const identity=await verifyToken(token);
   if(identity?.verified!==true||!ID.test(identity.uid))return{status:401,body:{error:'authentication_required'}};
   if(method==='POST'&&path==='/v1/award'){
    if(!body||Object.keys(body).sort().join(',')!=='kind,sourceId')return{status:400,body:{error:'invalid_request'}};
    const result=await service.award({token,...body});
    return{status:200,body:{schemaVersion:1,uid:identity.uid,policy,result}};
   }
   if(method==='GET'&&path==='/v1/profile'){
    const profile=await store.runTransaction(tx=>tx.get(`users/${identity.uid}/gamification/profile`));
    return{status:200,body:{schemaVersion:1,uid:identity.uid,policy,profile:profile??null}};
   }
   return{status:404,body:{error:'not_found'}};
  }catch(error){
   if(error instanceof ProgressionError)return{status:400,body:{error:error.code}};
   return{status:503,body:{error:'ledger_unavailable'}};
  }
 };
}
