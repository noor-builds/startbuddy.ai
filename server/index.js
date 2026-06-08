import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';

dotenv.config();

const app = express();
app.use((req, res, next) => {
  const origin = req.headers.origin;
  
  // Dynamically reflect the incoming origin back to the browser
  if (origin) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  
  // Crucial headers to pass preflight checks
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type', 'Authorization');
  res.setHeader('Access-Control-Allow-Credentials', 'true');

  // Handle the browser's automatic OPTIONS preflight request immediately
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }

  next();
});
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/auth', (await import('./routes/auth_route.js')).default);
app.use('/ai', (await import('./routes/ai_route.js')).default);
app.use('/integration', (await import('./routes/integration_route.js')).default);

const port = Number(process.env.PORT) || 3001;

if (!process.env.VERCEL) {
  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
}

export default app;
