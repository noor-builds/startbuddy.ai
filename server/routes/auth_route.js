import { Router } from "express";
import { registerUser } from "../middleware/auth/auth_service.js";


const router = Router();

router.post("/register", async (req, res) => {
    await registerUser(req, res);
});

export default router;

