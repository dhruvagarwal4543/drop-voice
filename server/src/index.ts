import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { handleTokenRequest } from './token';

// --- Environment validation ---
const required = ['LIVEKIT_URL', 'LIVEKIT_API_KEY', 'LIVEKIT_API_SECRET'];
const missing = required.filter((k) => !process.env[k]);
if (missing.length > 0) {
  console.error(`[startup] Missing required environment variables: ${missing.join(', ')}`);
  console.error('[startup] Copy server/.env.example to server/.env and fill in your credentials.');
  process.exit(1);
}

// --- Firebase Admin SDK ---
if (getApps().length === 0) {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (serviceAccountJson) {
    const serviceAccount = JSON.parse(serviceAccountJson);
    initializeApp({ credential: cert(serviceAccount) });
    console.log('[startup] Firebase Admin: initialized with service account JSON');
  } else if (process.env.FIREBASE_PROJECT_ID) {
    initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID });
    console.log(`[startup] Firebase Admin: initialized with project ID: ${process.env.FIREBASE_PROJECT_ID}`);
  } else {
    initializeApp();
    console.log('[startup] Firebase Admin: initialized with Application Default Credentials');
  }
}

const app = express();
const PORT = process.env.PORT ?? 3000;

// --- Middleware ---
app.use(cors({
  origin: '*', // Restrict to your app domain in production if needed
  methods: ['GET', 'POST'],
}));
app.use(express.json());

// Log every request
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// --- Routes ---

/** Health check — useful for deployment platforms */
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'dropvoice-token-server' });
});

/** Generate LiveKit token */
app.post('/token', handleTokenRequest);

// 404 fallback
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// --- Start server ---
app.listen(PORT, () => {
  console.log(`[dropvoice-server] Running on port ${PORT}`);
  console.log(`[dropvoice-server] LiveKit URL: ${process.env.LIVEKIT_URL}`);
});
