// Run only locally with a separately installed workerd binary.
// Generates throwaway synthetic RSA material in memory; never account credentials.
import {generateKeyPairSync,sign} from 'node:crypto';
import {spawn} from 'node:child_process';
import {readFileSync,writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const binary=process.env.WORKERD_BINARY;
if(!binary)throw Error('WORKERD_BINARY_required');
const root=dirname(fileURLToPath(import.meta.url)),dir=mkdtempSync(join(tmpdir(),'sufra-cpu-'));
const mods=['worker_qualification.mjs','engine.mjs','firestore_rest_store.mjs'];
for(const name of mods)writeFileSync(join(dir,name),readFileSync(join(root,name)));
const entries=mods.map(name=>`(name = "${name}", esModule = embed "${name}")`).join(',');
writeFileSync(join(dir,'config.capnp'),`using Workerd = import "/workerd/workerd.capnp";\nconst config :Workerd.Config = (services = [(name = "main", worker = (modules = [${entries}], compatibilityDate = "2026-11-24"))], sockets = [(name = "http", address = "127.0.0.1:8796", http = (), service = "main")]);`);
const child=spawn(binary,['serve',join(dir,'config.capnp')],{stdio:['ignore','pipe','pipe']});
let stderr='';child.stderr.on('data',x=>stderr+=x);
const origin='http://127.0.0.1:8796';
function cpuMs(){const s=readFileSync(`/proc/${child.pid}/stat`,'utf8').slice(readFileSync(`/proc/${child.pid}/stat`,'utf8').lastIndexOf(')')+2).split(' ');return(Number(s[11])+Number(s[12]))*10;}
const now=Date.parse('2026-11-24T12:00:00Z');
const{publicKey,privateKey}=generateKeyPairSync('rsa',{modulusLength:2048});
const b64=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const header=b64({alg:'RS256',kid:'synthetic'}),claims=b64({sub:'u',aud:'demo-sufra-progression',iss:'https://securetoken.google.com/demo-sufra-progression',iat:now/1000-10,auth_time:now/1000-20,exp:now/1000+3600});
const unsigned=header+'.'+claims,token=unsigned+'.'+sign('RSA-SHA256',Buffer.from(unsigned),privateKey).toString('base64url');
try{
 let ready=false;
 for(let i=0;i<100;i++){try{await fetch(origin);ready=true;break;}catch{await new Promise(r=>setTimeout(r,50));}}
 if(!ready)throw Error('workerd_start_failed '+stderr);
 const prepare=await fetch(origin+'/prepare',{method:'POST',body:JSON.stringify({now,token,publicJwk:publicKey.export({format:'jwk'}),privatePkcs8:privateKey.export({format:'der',type:'pkcs8'}).toString('base64url'),oauthAssertion:unsigned,config:JSON.parse(readFileSync(join(root,'../../assets/data/progression.json')))}),headers:{'content-type':'application/json'}});
 assert(prepare.ok,await prepare.text());
 assert.equal((await(await fetch(origin+'/forged')).json()).rejected,true);
 const results=[];
 for(const[kind,mode,n]of [['meal','warm',300],['meal','refresh',150],['meal','cold',150],['plan','cold',150],['profile','cold',150]]){
  for(let i=0;i<10;i++){const r=await fetch(`${origin}/award?kind=${kind}&mode=${mode}`);assert(r.ok,await r.text());}
  const c=cpuMs(),start=performance.now(),latencies=[];
  for(let i=0;i<n;i++){const t=performance.now();const r=await fetch(`${origin}/award?kind=${kind}&mode=${mode}`);const body=await r.json();assert(r.ok,JSON.stringify(body));assert.equal(body.requests,7);assert.equal(body.commits,1);latencies.push(performance.now()-t);}
  const cpu=cpuMs()-c,wall=performance.now()-start;latencies.sort((a,b)=>a-b);
  results.push({kind,mode,samples:n,workerProcessCpuTotalMs:cpu,workerProcessCpuMeanMs:cpu/n,wallMeanMs:wall/n,wallP95Ms:latencies[Math.floor(n*.95)],wallMaxMs:latencies.at(-1)});
 }
 console.log(JSON.stringify({runtime:'local workerd 2026-11-24',syntheticOnly:true,externalFetches:0,timingMethod:'Linux worker-process utime+stime at 100 Hz, batch mean. Wall times are client HTTP elapsed. Not per-request CPU or production qualification.',forgeryRejected:true,results},null,2));
}finally{
 if(child.exitCode===null&&child.signalCode===null){const ended=new Promise(resolve=>child.once('exit',resolve));child.kill('SIGTERM');await ended;}rmSync(dir,{recursive:true,force:true});
 if(stderr)console.error(stderr);
}
