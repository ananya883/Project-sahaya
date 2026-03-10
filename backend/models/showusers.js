import { MongoClient } from "mongodb";

const uri = "mongodb://localhost:27017"; // your MongoDB URL
const client = new MongoClient(uri);

async function run() {
  try {
    await client.connect();
    const db = client.db("myDatabase"); // your database name
    const users = await db.collection("users").find().toArray();
    console.log(users); // prints all users
  } finally {
    await client.close();
  }
}

run().catch(console.error);
