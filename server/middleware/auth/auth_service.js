
import { supabase } from "../../db.js";

 async function registerUser (req, res) {
    try {
        const { email, password } = req.body;   

        const { data, error } = await supabase.auth.signUp({ email, password });

        if (error) throw error;

        res.json(data);

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
 }

 export { registerUser };