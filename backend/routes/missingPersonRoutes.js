import express from "express";
import multer from "multer";
import mongoose from "mongoose";
import axios from "axios";
import path from "path";
import fs from "fs";
import FormData from "form-data";

import MissingPerson from "../models/MissingPerson.js";
import UnknownPerson from "../models/UnknownPerson.js";
import Match from "../models/Match.js";
import Notification from "../models/Notification.js";

const router = express.Router();

// ---------- Multer config ----------
const storage = multer.diskStorage({
  destination: "uploads/missing",
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  },
});
const upload = multer({ storage });

const AI_BASE_URL = "http://127.0.0.1:5002";
const MATCH_THRESHOLD = 0.85;

// ---------- REGISTER MISSING PERSON ----------
router.post("/register", upload.single("photo"), async (req, res) => {
  try {
    const {
      name,
      age,
      gender,
      height,
      weight,
      birthmark,
      lastSeenLocation,
      lastSeenDate,
      registeredBy,
    } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: "Photo required" });
    }

    if (!registeredBy) {
      return res.status(400).json({ message: "registeredBy required" });
    }

    const imagePath = path.resolve(req.file.path);

    let embedding = null;
    try {
      
      const formData = new FormData();
      formData.append("image", fs.createReadStream(imagePath));

      const aiRes = await axios.post(
        `${AI_BASE_URL}/extract`,
        formData,
        { headers: formData.getHeaders(), timeout: 10000 } // Increased timeout to 10s
      );

      if (aiRes.data && aiRes.data.embedding) {
        embedding = aiRes.data.embedding;
      }
    } catch (aiError) {
      console.warn("⚠️ AI Service unavailable/failed, skipping embedding:", aiError.message);
      // Proceed without embedding
    }

    // 2️⃣ Save missing person FIRST
    const person = await MissingPerson.create({
      name,
      age: age ? Number(age) : undefined,
      gender,
      height,
      weight,
      birthmark,
      lastSeenLocation,
      lastSeenDate,
      imagePath: req.file.path,
      faceEmbedding: embedding, // Can be null
      status: "missing",
      registeredBy: new mongoose.Types.ObjectId(registeredBy),
    });

    // 3️⃣ Respond IMMEDIATELY
    res.status(201).json({
      message: "Missing person registered. Matching running in background.",
      personId: person._id,
    });

    // 4️⃣ Run matching in BACKGROUND (do not await)
    if (embedding) {
      runMatchingInBackground(person, embedding).catch(err =>
        console.error("❌ Background matching error:", err)
      );
    }

  } catch (err) {
    console.error("❌ Missing register error:", err);
    res.status(500).json({ error: err.message });
  }
});

// Async function for background matching
async function runMatchingInBackground(person, embedding) {
  try {
    const unknownPeople = await UnknownPerson.find({
      status: { $in: ["active", "unknown"] },
    });

    for (const unknown of unknownPeople) {
      if (!unknown.faceEmbedding) continue;

      const matchRes = await axios.post(
        `${AI_BASE_URL}/match`,
        {
          embedding1: person.faceEmbedding,
          embedding2: unknown.faceEmbedding,
        },
        { timeout: 20000 }
      );

      const similarity = matchRes.data.similarity;

      if (similarity >= MATCH_THRESHOLD) {
        // Determine confidence level
        let confidence = "low";
        if (similarity >= 0.95) confidence = "high";
        else if (similarity >= 0.85) confidence = "medium";

        // Store match record
        const matchRecord = await Match.create({
          missingPerson: person._id,
          unknownPerson: unknown._id,
          similarity,
          confidenceLevel: confidence,
          status: "pending",
        });

        // Notify missing person reporter
        await Notification.create({
          userId: person.registeredBy,
          type: "match",
          title: "Possible Match Found",
          message: `A person possibly matching ${person.name} was found (${(
            similarity * 100
          ).toFixed(2)}% similarity). Please verify.`,
          relatedMissingPerson: person._id,
          relatedUnknownPerson: unknown._id,
          relatedMatch: matchRecord._id,
        });
      }
    }
  } catch (error) {
    console.error(`⚠️ Error in background matching for ${person._id}:`, error.message);
  }
}

export default router;
