import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

async function moveUser() {
    try {
        console.log("Connecting to MongoDB...");
        await mongoose.connect(process.env.MONGO_URI);

        const testDb = mongoose.connection.useDb('test');
        const sahayaDb = mongoose.connection.useDb('sahaya');

        const emailToMove = 'ananyams2015@gmail.com';

        console.log(`Searching for ${emailToMove} in 'test' database...`);
        const userInTest = await testDb.collection('users').findOne({ email: emailToMove });

        if (!userInTest) {
            console.error(`User ${emailToMove} not found in 'test' database.`);
            process.exit(1);
        }

        console.log(`Found user in 'test'. Roles: ${userInTest.roles}`);

        // Remove _id to avoid collision/immutable error
        const { _id, ...userData } = userInTest;

        console.log(`Updating user in 'sahaya' database...`);
        await sahayaDb.collection('users').updateOne(
            { email: emailToMove },
            { $set: userData },
            { upsert: true }
        );

        console.log("User successfully moved. Verify counts in sahaya:");
        const count = await sahayaDb.collection('users').countDocuments({ email: emailToMove });
        const userNow = await sahayaDb.collection('users').findOne({ email: emailToMove });
        console.log(`Count: ${count}, Roles: ${userNow?.roles}`);

        process.exit(0);
    } catch (err) {
        console.error("Error:", err);
        process.exit(1);
    }
}

moveUser();
