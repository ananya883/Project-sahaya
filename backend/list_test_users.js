import mongoose from 'mongoose';
import dotenv from 'dotenv';
import fs from 'fs';
dotenv.config();

async function listTestUsers() {
    let output = "";
    try {
        await mongoose.connect(process.env.MONGO_URI, { dbName: 'test' });
        const users = await mongoose.connection.db.collection('users').find({}, { projection: { email: 1, roles: 1 } }).toArray();

        output += "Users in 'test' database:\n";
        users.forEach(u => {
            output += `- ${u.email} (Roles: ${u.roles?.join(', ') || 'none'})\n`;
        });

        fs.writeFileSync('test_users_list.txt', output);
        process.exit(0);
    } catch (err) {
        fs.writeFileSync('test_users_list.txt', "Error: " + err.message);
        process.exit(1);
    }
}

listTestUsers();
