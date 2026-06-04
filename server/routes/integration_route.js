import { Router } from 'express';
import {
  notionOAuthCallback,
  signInWithNotion,
} from '../middleware/integration/notion.js';

const router = Router();

router.get('/notion/sign-in', signInWithNotion);
router.post('/notion/sign-in', signInWithNotion);
router.get('/notion/callback', notionOAuthCallback);

export default router;
