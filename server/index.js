import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';

dotenv.config();

const app = express();

function parseAllowedOrigins() {
  return (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

function isLocalDevOrigin(origin) {
  return /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin);
}

app.use(
  cors({
    origin(origin, callback) {
      // Non-browser clients (curl, mobile) send no Origin header.
      if (!origin) return callback(null, true);

      const allowed = parseAllowedOrigins();
      if (isLocalDevOrigin(origin) || allowed.includes(origin)) {
        return callback(null, true);
      }

      try {
        const { hostname } = new URL(origin);
        if (hostname.endsWith('.vercel.app')) {
          return callback(null, true);
        }
      } catch {
        return callback(null, false);
      }

      if (process.env.NODE_ENV !== 'production') {
        return callback(null, true);
      }

      return callback(null, false);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

app.use(express.json());

app.use('/auth', (await import('./routes/auth_route.js')).default);
app.use('/ai', (await import('./routes/ai_route.js')).default);

const port = Number(process.env.PORT) || 3001;

if (!process.env.VERCEL) {
  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
}

export default app;
