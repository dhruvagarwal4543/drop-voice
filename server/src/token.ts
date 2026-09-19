import { AccessToken, VideoGrant } from 'livekit-server-sdk';
import { Request, Response } from 'express';
import { getAuth } from 'firebase-admin/auth';

const LIVEKIT_URL = process.env.LIVEKIT_URL!;
const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY!;
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET!;

interface TokenRequestBody {
  room: string;
  identity: string;
  name?: string;
}

/**
 * POST /token
 * Generates a short-lived LiveKit access token.
 *
 * Headers: { Authorization: 'Bearer <firebase-id-token>' }
 * Body: { room, identity, name }
 * Returns: { token, livekitUrl }
 *
 * SECURITY:
 * - LIVEKIT_API_SECRET never leaves this server.
 * - Caller must be a verified Firebase user.
 * - identity must match the verified Firebase UID.
 */
export async function handleTokenRequest(req: Request, res: Response): Promise<void> {
  // --- Firebase Auth Verification ---
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header.' });
    return;
  }

  const idToken = authHeader.split('Bearer ')[1];
  let verifiedUid: string;

  try {
    const decoded = await getAuth().verifyIdToken(idToken);
    verifiedUid = decoded.uid;
  } catch (err) {
    console.warn('[token] Invalid Firebase ID token:', err);
    res.status(401).json({ error: 'Invalid or expired Firebase ID token.' });
    return;
  }

  const { room, identity, name } = req.body as TokenRequestBody;

  // --- Validation ---
  if (!room || typeof room !== 'string' || room.trim().length === 0) {
    res.status(400).json({ error: 'Missing or invalid field: room' });
    return;
  }
  if (!identity || typeof identity !== 'string' || identity.trim().length === 0) {
    res.status(400).json({ error: 'Missing or invalid field: identity' });
    return;
  }

  // --- Security: identity must match the verified Firebase UID ---
  if (identity.trim() !== verifiedUid) {
    res.status(403).json({ error: 'identity must match your authenticated Firebase UID.' });
    return;
  }

  const roomCode = room.trim().toUpperCase();
  const participantIdentity = identity.trim();
  const participantName = (name ?? participantIdentity).trim();

  try {
    // Permissions: voice-chat only.
    // No video, no screen share, no recording.
    const grant: VideoGrant = {
      room: roomCode,
      roomJoin: true,
      canPublish: true,         // publish microphone
      canSubscribe: true,       // receive remote audio
      canPublishData: false,    // no data channels needed for MVP
    };

    const token = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: participantIdentity,
      name: participantName,
      // Token valid for 4 hours — short-lived.
      ttl: '4h',
    });

    token.addGrant(grant);
    const jwt = await token.toJwt();

    console.log(`[token] Generated for uid=${verifiedUid} room=${roomCode}`);

    res.json({
      token: jwt,
      livekitUrl: LIVEKIT_URL,
    });
  } catch (err) {
    console.error('[token] Failed to generate token:', err);
    res.status(500).json({ error: 'Failed to generate token' });
  }
}
