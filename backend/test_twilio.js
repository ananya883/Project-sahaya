import dotenv from 'dotenv';
import twilio from 'twilio';
import mongoose from 'mongoose';
import User from './models/users.js';

dotenv.config();

const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID;
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN;
const TWILIO_PHONE_NUMBER = process.env.TWILIO_PHONE_NUMBER;

async function runDiagnostics() {
    console.log("=== TWILIO DIAGNOSTIC ===");
    console.log("SID:", TWILIO_ACCOUNT_SID ? "Found" : "Missing");
    console.log("Token:", TWILIO_AUTH_TOKEN ? "Found" : "Missing");
    console.log("From Number:", TWILIO_PHONE_NUMBER ? "Found" : "Missing");

    if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN) {
        console.error("Twilio credentials are not set in .env!");
        process.exit(1);
    }

    const client = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);

    try {
        await mongoose.connect(process.env.MONGO_URI, { dbName: "sahaya" });
        console.log("Connected to MongoDB.");
        
        const users = await User.find({}, 'Name mobile');
        console.log(`Found ${users.length} users in database.`);
        
        let foundTargets = 0;
        for (const user of users) {
             let phoneNum = user.mobile?.toString();
             if (phoneNum && phoneNum.length >= 10) {
                 if (!phoneNum.startsWith('+')) {
                     phoneNum = `+91${phoneNum}`;
                 }
                 console.log(`User: ${user.Name}, Formatted Mobile: ${phoneNum}`);
                 foundTargets++;
             }
        }
        console.log(`Will attempt to send to ${foundTargets} valid phone numbers.`);
        
        mongoose.disconnect();
    } catch (e) {
        console.error("Diagnostic error:", e);
    }
}

runDiagnostics();
