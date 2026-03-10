import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

async function checkEmail() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        const admin = mongoose.connection.db.admin();
        const dbsInfo = await admin.listDatabases();

        const targetEmail = 'ananyams@gmail.com';
        console.log(`Searching for email: ${targetEmail} in all databases...`);

        for (const dbInfo of dbsInfo.databases) {
            const db = mongoose.connection.useDb(dbInfo.name).db;
            const collections = await db.listCollections().toArray();
            for (const coll of collections) {
                const count = await db.collection(coll.name).countDocuments({ email: targetEmail });
                if (count > 0) {
                    console.log(`[FOUND] In DB: ${dbInfo.name}, Collection: ${coll.name}`);
                }
            }
        }
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkEmail();
