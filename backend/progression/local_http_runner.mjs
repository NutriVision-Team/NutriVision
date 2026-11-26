// Demo-only local test runner. Never a production server entrypoint.
import {createServer} from 'node:http';
import {spawn} from 'node:child_process';
import {FirestoreRestStore,encodeFields} from './firestore_rest_store.mjs';
import {TrustedProgressionService} from './engine.mjs';
import {localLedgerContract} from './local_contract.mjs';
import {readFileSync} from 'node:fs';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8089')throw Error('demo_emulator_required');
const projectId='demo-sufra-progression';
const base=`http://127.0.0.1:8089/v1/projects/${projectId}/databases/(default)/documents/`;
const config=JSON.parse(readFileSync(new URL('../../assets/data/progression.json',import.meta.url)));
for(const[path,data]of [['app_config/gamification',config],['users/u/meal_entries/httpmeal',{userId:'u',title:'Synthetic HTTP meal',dateKey:new Date().toISOString().slice(0,10),analysisStatus:'confirmed'}]]){
 const response=await fetch(base+path,{method:'PATCH',headers:{Authorization:'Bearer owner','Content-Type':'application/json'},body:JSON.stringify({fields:encodeFields(data)})});if(!response.ok)throw Error('demo_seed_failed');
}
const store=new FirestoreRestStore({projectId,emulatorOrigin:'http://127.0.0.1:8089',getAccessToken:async()=>'owner'});
const verifyToken=async token=>token==='demo-u'?{uid:'u',verified:true}:token==='demo-other'?{uid:'other',verified:true}:null;
const service=new TrustedProgressionService({store,verifyToken});
const handler=localLedgerContract({store,service,verifyToken,policy:{status:'provisional',dayBasis:'UTC',retention:'unresolved'}});
const server=createServer(async(req,res)=>{
 if(req.socket.remoteAddress!=='127.0.0.1'){res.writeHead(403).end();return;}
 try{
  let text='';for await(const chunk of req){text+=chunk;if(text.length>1024)throw Error('too_large');}
  const result=await handler({method:req.method,path:req.url,authorization:req.headers.authorization,body:text?JSON.parse(text):undefined});
  res.writeHead(result.status,{'Content-Type':'application/json'}).end(JSON.stringify(result.body));
 }catch{res.writeHead(400).end('{}');}
});
await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(8795,'127.0.0.1',resolve);});
try{
 const child=spawn('/home/sandbox/sdk/flutter/bin/flutter',['test','--no-pub','test/gamification/trusted_ledger_http_test.dart','--reporter','expanded'],{stdio:'inherit',env:{...process.env,SUFRA_DEMO_LEDGER_HTTP:'127.0.0.1:8795'}});
 const timer=setTimeout(()=>child.kill('SIGTERM'),60000);
 const code=await new Promise(resolve=>child.on('exit',resolve));clearTimeout(timer);
 if(code!==0)throw Error('dart_http_integration_failed');
 const profile=await store.runTransaction(tx=>tx.get('users/u/gamification/profile'));
 if(profile.totalXp!==10||profile.counts.meal!==1)throw Error('wrong_durable_state');
 console.log('PASS: actual Dart HTTP request -> local verified contract -> demo Firestore ledger -> Dart response, independent durable readback.');
}finally{await new Promise(resolve=>server.close(resolve));}
