// Sufra password-reset code Worker (Cloudflare free plan + KV).
// Secrets (never in repo): SA_KEY (service account JSON), SMTP_USER, SMTP_PASS.
import {connect} from 'cloudflare:sockets';

const enc = new TextEncoder();
const CODE_TTL = 300; // seconds, shown as a countdown in the app
const MAX_ATTEMPTS = 5;
const json = (b, s = 200) => new Response(JSON.stringify(b), {status: s, headers: {'content-type': 'application/json', 'cache-control': 'no-store', 'access-control-allow-origin': '*', 'access-control-allow-headers': 'content-type', 'access-control-allow-methods': 'POST,OPTIONS'}});
const b64u = (buf) => btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const hex = (buf) => [...new Uint8Array(buf)].map((x) => x.toString(16).padStart(2, '0')).join('');

async function adminToken(env) {
  const sa = JSON.parse(env.SA_KEY);
  const now = Math.floor(Date.now() / 1000);
  const head = b64u(enc.encode(JSON.stringify({alg: 'RS256', typ: 'JWT'})));
  const claim = b64u(enc.encode(JSON.stringify({iss: sa.client_email, scope: 'https://www.googleapis.com/auth/cloud-platform', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3300})));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', der, {name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256'}, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(`${head}.${claim}`));
  const r = await fetch('https://oauth2.googleapis.com/token', {method: 'POST', headers: {'content-type': 'application/x-www-form-urlencoded'}, body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${head}.${claim}.${b64u(sig)}`});
  if (!r.ok) throw new Error('token');
  return [(await r.json()).access_token, sa.project_id];
}

async function lookup(env, email) {
  const [tok, project] = await adminToken(env);
  const r = await fetch(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:lookup`, {method: 'POST', headers: {authorization: `Bearer ${tok}`, 'content-type': 'application/json'}, body: JSON.stringify({email: [email]})});
  const d = await r.json();
  return d.users && d.users[0] ? d.users[0] : null;
}

async function setPassword(env, localId, password) {
  const [tok, project] = await adminToken(env);
  const r = await fetch(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:update`, {method: 'POST', headers: {authorization: `Bearer ${tok}`, 'content-type': 'application/json'}, body: JSON.stringify({localId, password})});
  return r.ok;
}

async function digest(code, email, env) {
  return hex(await crypto.subtle.digest('SHA-256', enc.encode(`${code}|${email}|${env.SMTP_USER}`)));
}

// ---- minimal SMTP over implicit TLS (smtp.gmail.com:465) ----
async function smtpSend(env, to, subject, text) {
  const sock = connect({hostname: 'smtp.gmail.com', port: 465}, {secureTransport: 'on'});
  const reader = sock.readable.getReader();
  const writer = sock.writable.getWriter();
  const dec = new TextDecoder();
  let buf = '';
  const read = async () => {
    for (;;) {
      const lines = buf.split('\r\n');
      for (let i = 0; i < lines.length - 1; i++) {
        if (/^\d{3} /.test(lines[i])) { const code = Number(lines[i].slice(0, 3)); buf = lines.slice(i + 1).join('\r\n'); return code; }
      }
      const {value, done} = await reader.read();
      if (done) throw new Error('smtp closed');
      buf += dec.decode(value);
    }
  };
  const send = async (line, expect) => { await writer.write(enc.encode(line + '\r\n')); const c = await read(); if (expect && c !== expect) throw new Error(`smtp ${c}`); return c; };
  try {
    if ((await read()) !== 220) throw new Error('greet');
    await send('EHLO sufra.worker', 250);
    await send('AUTH LOGIN', 334);
    await send(btoa(env.SMTP_USER), 334);
    await send(btoa(env.SMTP_PASS), 235);
    await send(`MAIL FROM:<${env.SMTP_USER}>`, 250);
    await send(`RCPT TO:<${to}>`, 250);
    await send('DATA', 354);
    const subj = `=?UTF-8?B?${btoa(String.fromCharCode(...enc.encode(subject)))}?=`;
    const body = btoa(String.fromCharCode(...enc.encode(text))).replace(/(.{76})/g, '$1\r\n');
    const msg = [`From: Sufra <${env.SMTP_USER}>`, `To: <${to}>`, `Subject: ${subj}`, 'MIME-Version: 1.0', 'Content-Type: text/plain; charset=UTF-8', 'Content-Transfer-Encoding: base64', '', body, '.'].join('\r\n');
    await send(msg, 250);
    await send('QUIT');
  } finally { try { await writer.close(); } catch {} }
}

export default {async fetch(req, env) {
  if (req.method === 'OPTIONS') return json({}, 204);
  const url = new URL(req.url);
  if (req.method === 'GET' && url.pathname === '/health') return json({service: 'sufra-reset', ok: true});
  if (req.method !== 'POST') return json({error: 'not_found'}, 404);
  let body; try { body = await req.json(); } catch { return json({error: 'invalid_request'}, 400); }
  const email = String(body.email || '').trim().toLowerCase();
  if (!/^[^@\s]{1,64}@[^@\s]{1,255}$/.test(email)) return json({error: 'invalid_request'}, 400);

  if (url.pathname === '/request') {
    const rl = await env.RESET.get(`rl:${email}`);
    if (rl) return json({error: 'rate_limited'}, 429);
    await env.RESET.put(`rl:${email}`, '1', {expirationTtl: 60});
    const user = await lookup(env, email).catch(() => null);
    if (user) {
      const code = String(crypto.getRandomValues(new Uint32Array(1))[0] % 1000000).padStart(6, '0');
      await env.RESET.put(`code:${email}`, JSON.stringify({h: await digest(code, email, env), uid: user.localId, t: Date.now(), a: 0}), {expirationTtl: CODE_TTL + 30});
      await smtpSend(env, email, 'Sufra | رمز استعادة كلمة المرور', `رمز التحقق الخاص بك في سُفرة: ${code}\nصالح لمدة 5 دقائق. لو ما طلبتش ده تجاهل الرسالة.\n\nYour Sufra reset code: ${code}\nValid for 5 minutes. If you did not request this, ignore this email.`);
    }
    return json({ok: true, expiresIn: CODE_TTL});
  }

  if (url.pathname === '/confirm') {
    const code = String(body.code || ''); const pw = String(body.newPassword || '');
    if (!/^\d{6}$/.test(code)) return json({error: 'invalid_code'}, 400);
    if (pw.length < 8 || pw.length > 128) return json({error: 'weak_password'}, 400);
    const raw = await env.RESET.get(`code:${email}`);
    if (!raw) return json({error: 'expired'}, 400);
    const rec = JSON.parse(raw);
    if (Date.now() - rec.t > CODE_TTL * 1000) { await env.RESET.delete(`code:${email}`); return json({error: 'expired'}, 400); }
    if (rec.a >= MAX_ATTEMPTS) { await env.RESET.delete(`code:${email}`); return json({error: 'rate_limited'}, 429); }
    if ((await digest(code, email, env)) !== rec.h) {
      rec.a += 1; await env.RESET.put(`code:${email}`, JSON.stringify(rec), {expirationTtl: 60});
      return json({error: 'invalid_code'}, 400);
    }
    await env.RESET.delete(`code:${email}`);
    if (!(await setPassword(env, rec.uid, pw))) return json({error: 'unknown'}, 500);
    return json({ok: true});
  }
  return json({error: 'not_found'}, 404);
}};
