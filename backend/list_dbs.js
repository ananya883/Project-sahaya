import mongoose from 'mongoose';
import dotenv from 'dotenv';
import fs from 'fs';
dotenv.config();

async function listDBs() {
    let output = "";
    try {
        output += "Connecting...\n";
        await mongoose.connect(process.env.MONGO_URI);
        output += "Connected.\n";

        const admin = mongoose.connection.db.admin();
        const dbsInfo = await admin.listDatabases();
        output += "Databases found:\n";
        for (const dbInfo of dbsInfo.databases) {
            output += "- " + dbInfo.name + "\n";
        }

        // Check common suspects
        const suspects = dbsInfo.databases.map(d => d.name);
        if (!suspects.includes('sahaya')) suspects.push('sahaya');
        if (!suspects.includes('test')) suspects.push('test');

        for (const dbName of suspects) {
            try {
                const dbConn = mongoose.connection.useDb(dbName);
                const db = dbConn.db;
                const collections = await db.listCollections().toArray();
                output += `\nDB: ${dbName}\n`;
                for (const coll of collections) {
                    const count = await db.collection(coll.name).countDocuments();
                    output += `  - ${coll.name}: ${count} docs\n`;
                    if (coll.name === 'users' && count > 0) {
                        const sample = await db.collection(coll.name).findOne({}, { projection: { email: 1 } });
                        output += `    Sample email: ${sample?.email}\n`;
                    }
                }
            } catch (dbErr) {
                output += `\nError accessing DB ${dbName}: ${dbErr.message}\n`;
            }
        }

        fs.writeFileSync('db_diagnostic.txt', output);
        process.exit(0);
    } catch (err) {
        fs.writeFileSync('db_diagnostic.txt', "Global Error: " + err.message + "\n" + err.stack);
        process.exit(1);
    }
}

listDBs();
