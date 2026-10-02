import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import fs from 'node:fs/promises';
import path from 'node:path';

const app = express();
const PORT = Number(process.env.PORT || 8787);
const JWT_SECRET = process.env.JWT_SECRET || '';
if (!JWT_SECRET || JWT_SECRET.length < 32) throw new Error('JWT_SECRET must be at least 32 characters.');

const DATA_DIR = path.resolve('./data');
const DB_FILE = path.join(DATA_DIR, 'jarvis.json');
const FREE_IMAGES = 7;
const FREE_VIDEOS = 3;
const db = { users: {}, phoneOtps: {}, usage: {}, subscriptions: {} };

async function loadDb() {
  await fs.mkdir(DATA_DIR, { recursive: true });
  try { Object.assign(db, JSON.parse(await fs.readFile(DB_FILE, 'utf8'))); } catch (_) { await saveDb(); }
}
async function saveDb() { const tmp = `${DB_FILE}.tmp`; await fs.writeFile(tmp, JSON.stringify(db, null, 2)); await fs.rename(tmp, DB_FILE); }
function id() { return crypto.randomUUID(); }
function tokenFor(user) { return jwt.sign({ sub: user.id, role: user.role }, JWT_SECRET, { expiresIn: '30d', issuer: 'jarvis' }); }
function normalizeEmail(v) { return String(v || '').trim().toLowerCase(); }
function today() { return new Date().toISOString().slice(0, 10); }
function usageFor(userId) { const key = `${userId}:${today()}`; db.usage[key] ??= { images: 0, videos: 0 }; return db.usage[key]; }
function isPro(userId) { const s = db.subscriptions[userId]; return !!s && s.plan !== 'free' && (!s.expiresAt || new Date(s.expiresAt) > new Date()); }
function auth(req, res, next) {
  const h = req.headers.authorization || ''; const t = h.startsWith('Bearer ') ? h.slice(7) : '';
  try { const p = jwt.verify(t, JWT_SECRET, { issuer: 'jarvis' }); const user = db.users[p.sub]; if (!user) throw new Error('user'); req.user = user; next(); }
  catch (_) { res.status(401).json({ message: 'جلسة غير صالحة أو منتهية.' }); }
}
function publicUser(u) { return { id: u.id, email: u.email || null, phone: u.phone || null, displayName: u.displayName || '', role: u.role, provider: u.provider || 'password' }; }
function createUser(fields) { const user = { id: id(), email: fields.email || '', phone: fields.phone || '', displayName: fields.displayName || '', passwordHash: fields.passwordHash || '', provider: fields.provider || 'password', role: 'user', createdAt: new Date().toISOString() }; db.users[user.id] = user; return user; }

app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(rateLimit({ windowMs: 60_000, limit: 120, standardHeaders: true, legacyHeaders: false }));

app.get('/health', (_, res) => res.json({ ok: true, service: 'JARVIS backend', time: new Date().toISOString() }));

app.post('/auth/register', async (req, res) => {
  const email = normalizeEmail(req.body.email); const password = String(req.body.password || '');
  if (!/^\S+@\S+\.\S+$/.test(email) || password.length < 8) return res.status(400).json({ message: 'البريد غير صحيح أو كلمة المرور أقل من 8 أحرف.' });
  if (Object.values(db.users).some(u => u.email === email)) return res.status(409).json({ message: 'البريد مستخدم مسبقاً.' });
  const user = createUser({ email, displayName: String(req.body.displayName || ''), passwordHash: await bcrypt.hash(password, 12) });
  await saveDb(); res.json({ token: tokenFor(user), user: publicUser(user) });
});

app.post('/auth/login', async (req, res) => {
  const provider = String(req.body.provider || 'password');
  if (provider === 'phone') {
    const phone = String(req.body.phone || '').trim(); const otp = String(req.body.otp || '').trim();
    const record = db.phoneOtps[phone];
    if (!record || record.expiresAt < Date.now() || record.otp !== otp) return res.status(401).json({ message: 'رمز التحقق غير صحيح أو منتهي.' });
    let user = Object.values(db.users).find(u => u.phone === phone); if (!user) user = createUser({ phone, provider: 'phone' });
    delete db.phoneOtps[phone]; await saveDb(); return res.json({ token: tokenFor(user), user: publicUser(user) });
  }
  const email = normalizeEmail(req.body.identifier); const password = String(req.body.password || '');
  const user = Object.values(db.users).find(u => u.email === email);
  if (!user || !user.passwordHash || !(await bcrypt.compare(password, user.passwordHash))) return res.status(401).json({ message: 'البريد أو كلمة المرور غير صحيحة.' });
  res.json({ token: tokenFor(user), user: publicUser(user) });
});

app.post('/auth/phone/request', async (req, res) => {
  const phone = String(req.body.phone || '').trim(); if (!/^\+?[0-9]{8,15}$/.test(phone)) return res.status(400).json({ message: 'رقم الهاتف غير صحيح.' });
  const otp = String(crypto.randomInt(100000, 1000000)); db.phoneOtps[phone] = { otp, expiresAt: Date.now() + 5 * 60_000 }; await saveDb();
  if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_FROM) {
    const body = new URLSearchParams({ To: phone, From: process.env.TWILIO_FROM, Body: `JARVIS verification code: ${otp}` });
    const basic = Buffer.from(`${process.env.TWILIO_ACCOUNT_SID}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');
    const r = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${process.env.TWILIO_ACCOUNT_SID}/Messages.json`, { method: 'POST', headers: { authorization: `Basic ${basic}`, 'content-type': 'application/x-www-form-urlencoded' }, body });
    if (!r.ok) return res.status(502).json({ message: 'تعذر إرسال SMS.' });
  } else {
    console.log(`[JARVIS DEV OTP] ${phone}: ${otp}`);
  }
  res.json({ ok: true, message: 'تم إرسال رمز التحقق.' });
});

app.get('/auth/me', auth, (req, res) => res.json({ user: publicUser(req.user), pro: isPro(req.user.id) }));

const oauthStates = new Map();
function oauthState(provider) { const state = crypto.randomBytes(24).toString('hex'); oauthStates.set(state, { provider, expiresAt: Date.now() + 10 * 60_000 }); return state; }
app.get('/auth/oauth/google/start', (req, res) => {
  if (!process.env.GOOGLE_CLIENT_ID || !process.env.APP_URL) return res.status(501).json({ message: 'Google OAuth يحتاج GOOGLE_CLIENT_ID وAPP_URL.' });
  const state = oauthState('google'); const redirect = `${process.env.APP_URL}/auth/oauth/google/callback`;
  const q = new URLSearchParams({ client_id: process.env.GOOGLE_CLIENT_ID, redirect_uri: redirect, response_type: 'code', scope: 'openid email profile', access_type: 'offline', state });
  res.redirect(`https://accounts.google.com/o/oauth2/v2/auth?${q}`);
});
app.get('/auth/oauth/google/callback', async (req, res) => {
  try {
    const state = oauthStates.get(String(req.query.state || '')); if (!state || state.expiresAt < Date.now()) return res.status(400).send('Invalid OAuth state'); oauthStates.delete(String(req.query.state));
    const code = String(req.query.code || ''); const redirect = `${process.env.APP_URL}/auth/oauth/google/callback`;
    const body = new URLSearchParams({ code, client_id: process.env.GOOGLE_CLIENT_ID, client_secret: process.env.GOOGLE_CLIENT_SECRET || '', redirect_uri: redirect, grant_type: 'authorization_code' });
    const tokenRes = await fetch('https://oauth2.googleapis.com/token', { method:'POST', headers:{'content-type':'application/x-www-form-urlencoded'}, body }); const token = await tokenRes.json(); if(!token.access_token) throw new Error('Google token exchange failed');
    const infoRes = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', { headers:{authorization:`Bearer ${token.access_token}`} }); const info = await infoRes.json();
    let user = Object.values(db.users).find(u => u.provider==='google' && u.email===normalizeEmail(info.email)); if(!user) user=createUser({email:normalizeEmail(info.email),displayName:info.name||'',provider:'google'}); await saveDb();
    res.redirect(`jarvis://auth?token=${encodeURIComponent(tokenFor(user))}`);
  } catch(e) { res.status(502).send(e.message); }
});
app.get('/auth/oauth/apple/start', (req, res) => {
  if (!process.env.APPLE_CLIENT_ID || !process.env.APP_URL) return res.status(501).json({ message: 'Apple OAuth يحتاج APPLE_CLIENT_ID وAPP_URL.' });
  const state=oauthState('apple'); const redirect=`${process.env.APP_URL}/auth/oauth/apple/callback`;
  const q=new URLSearchParams({ client_id:process.env.APPLE_CLIENT_ID, redirect_uri:redirect, response_type:'code', response_mode:'query', scope:'name email', state });
  res.redirect(`https://appleid.apple.com/auth/authorize?${q}`);
});
app.get('/auth/oauth/apple/callback', async (req,res) => {
  try {
    const state=oauthStates.get(String(req.query.state||'')); if(!state||state.expiresAt<Date.now()) return res.status(400).send('Invalid OAuth state'); oauthStates.delete(String(req.query.state));
    if(!process.env.APPLE_CLIENT_SECRET) return res.status(501).send('APPLE_CLIENT_SECRET not configured');
    const body=new URLSearchParams({client_id:process.env.APPLE_CLIENT_ID,client_secret:process.env.APPLE_CLIENT_SECRET,code:String(req.query.code||''),grant_type:'authorization_code',redirect_uri:`${process.env.APP_URL}/auth/oauth/apple/callback`});
    const tokenRes=await fetch('https://appleid.apple.com/auth/token',{method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},body}); const data=await tokenRes.json(); if(!data.id_token) throw new Error('Apple token exchange failed');
    const jwks=createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys')); const verified=await jwtVerify(data.id_token,jwks,{issuer:'https://appleid.apple.com',audience:process.env.APPLE_CLIENT_ID}); const claims=verified.payload;
    const email=normalizeEmail(claims.email); let user=Object.values(db.users).find(u=>u.provider==='apple'&&u.email===email); if(!user) user=createUser({email,displayName:'',provider:'apple'}); await saveDb();
    res.redirect(`jarvis://auth?token=${encodeURIComponent(tokenFor(user))}`);
  } catch(e) { res.status(502).send(e.message); }
});

app.post('/auth/oauth/exchange', async (req, res) => {
  const provider = String(req.body.provider || '');
  const accessToken = String(req.body.accessToken || '');
  if (!accessToken || !['google', 'apple'].includes(provider)) return res.status(400).json({ message: 'بيانات OAuth غير مكتملة.' });
  // The mobile app may exchange a provider token here. Production deployments
  // should verify the token against the provider before creating a session.
  // This endpoint intentionally refuses unknown/unverified claims.
  return res.status(501).json({ message: `ربط ${provider} يحتاج مفاتيح OAuth الخاصة بالمشروع على الخادم.` });
});

app.get('/billing/status', auth, (req, res) => { const s = db.subscriptions[req.user.id] || { plan: 'free', expiresAt: null }; res.json(s); });
app.post('/billing/verify', auth, async (req, res) => {
  // Never trust a purchase token on its own. The store-side verification
  // adapters are intentionally explicit so production credentials must exist.
  return res.status(501).json({ message: 'تحقق المتجر يحتاج إعداد Google Play/App Store Server API على الخادم قبل تفعيل الاشتراك الحقيقي.' });
});

async function openai(pathname, body) {
  const key = process.env.OPENAI_API_KEY; if (!key) throw new Error('OPENAI_API_KEY is not configured on the server.');
  const r = await fetch(`https://api.openai.com${pathname}`, { method: 'POST', headers: { authorization: `Bearer ${key}`, 'content-type': 'application/json' }, body: JSON.stringify(body) });
  const text = await r.text(); let data; try { data = JSON.parse(text); } catch (_) { data = { message: text }; }
  if (!r.ok) throw new Error(data?.error?.message || data?.message || `OpenAI HTTP ${r.status}`); return data;
}
function requireQuota(req, type) {
  if (req.user.role === 'developer' || isPro(req.user.id)) return;
  const u = usageFor(req.user.id); const limit = type === 'image' ? FREE_IMAGES : FREE_VIDEOS;
  if (u[type === 'image' ? 'images' : 'videos'] >= limit) throw new Error(type === 'image' ? 'وصلت إلى حد الصور المجاني اليوم: 7.' : 'وصلت إلى حد الفيديو المجاني اليوم: 3.');
}
app.post('/ai/chat', auth, async (req, res) => {
  try { const prompt = String(req.body.prompt || '').trim(); if (!prompt) return res.status(400).json({ message: 'prompt مطلوب.' }); const data = await openai('/v1/responses', { model: process.env.OPENAI_MODEL || 'gpt-5.6-luna', input: [{ role: 'user', content: [{ type: 'input_text', text: prompt }] }] }); res.json({ output_text: data.output_text || '', raw: data }); }
  catch (e) { res.status(502).json({ message: e.message }); }
});
app.post('/ai/image', auth, async (req, res) => {
  try { requireQuota(req, 'image'); const data = await openai('/v1/images/generations', { model: process.env.OPENAI_IMAGE_MODEL || 'gpt-image-2', prompt: String(req.body.prompt || ''), size: '1024x1024' }); const u=usageFor(req.user.id); if(req.user.role!=='developer'&&!isPro(req.user.id))u.images++; await saveDb(); res.json({ ...data, usage: { imagesUsed:u.images, videosUsed:u.videos } }); }
  catch (e) { res.status(502).json({ message: e.message }); }
});
app.post('/ai/video', auth, async (req, res) => {
  try {
    requireQuota(req, 'video');
    const url = process.env.AI_VIDEO_URL; if (!url) throw new Error('AI_VIDEO_URL غير مضبوط.');
    const key = process.env.OPENAI_API_KEY; if (!key) throw new Error('OPENAI_API_KEY غير مضبوط.');
    const r = await fetch(url, { method:'POST', headers:{authorization:`Bearer ${key}`,'content-type':'application/json'}, body:JSON.stringify({ model:process.env.AI_VIDEO_MODEL || 'sora-2', prompt:String(req.body.prompt||''), duration:Number(req.body.duration||10) }) });
    const data = await r.json(); if(!r.ok) throw new Error(data?.error?.message || `Video provider HTTP ${r.status}`);
    const u=usageFor(req.user.id); if(req.user.role!=='developer'&&!isPro(req.user.id))u.videos++; await saveDb(); res.json({...data,usage:{imagesUsed:u.images,videosUsed:u.videos}});
  } catch(e) { res.status(502).json({message:e.message}); }
});

await loadDb();
app.listen(PORT, '0.0.0.0', () => console.log(`JARVIS backend listening on :${PORT}`));
