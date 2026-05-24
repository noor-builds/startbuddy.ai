import express from 'express';
import dotenv from 'dotenv';
import { supabase } from './db.js';

dotenv.config()

const app = express();
app.use(express.json());


//auth routes

app.use("/auth", (await import("./routes/auth_route.js")).default);



app.listen(process.env.PORT, () => {
    console.log(`Server is running on port ${process.env.PORT}`);
});