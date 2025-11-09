import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { z } from 'zod';
import Twilio from 'twilio';

const app = express();
app.use(cors());                 // tighten origins in prod
app.use(express.json());

const client = Twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
const FROM = process.env.TWILIO_MESSAGING_SERVICE_SID || process.env.TWILIO_FROM;

// Simple auth guard
app.use((req, res, next) => {
  const key = req.header('x-api-key');
  if (!process.env.API_KEY || key === process.env.API_KEY) return next();
  return res.status(401).json({ error: 'Unauthorized' });
});

// POST /send-sms  { to: "+14165550123", message: "Hello" }
app.post('/send-sms', async (req, res) => {
  try {
    const schema = z.object({
      to: z.string().regex(/^\+\d{7,15}$/),      // E.164 only
      message: z.string().min(1).max(640)        // keep it SMS-sized
    });
    const { to, message } = schema.parse(req.body);

    const params = FROM?.startsWith('MG')
      ? { to, body: message, messagingServiceSid: FROM }
      : { to, body: message, from: FROM };

    const msg = await client.messages.create(params);
    res.json({ sid: msg.sid, status: 'queued' });
  } catch (e) {
    const code = e.status || 500;
    res.status(code).json({ error: e.message || 'send failed' });
  }
});

app.listen(process.env.PORT || 3000, '0.0.0.0', () => {
  console.log('SMS API running on', process.env.PORT || 3000);
});
