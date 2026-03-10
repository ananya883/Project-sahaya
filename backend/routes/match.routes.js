import express from "express";
import multer from "multer";
import path from "path";
import axios from "axios";

import MissingPerson from "../models/MissingPerson.js";
import Notification from "../models/Notification.js";
import MatchResult from "../models/Match.js";

const router = express.Router();

// --------------------
// Multer configuration
// --------------------
const upload = multer({ dest: "uploads/" });

// --------------------
// MATCH FOUND ROUTE
// --------------------
router.post("/match-found", upload.single("photo"), async (req, res) => {
  try {
    console.log("🔥 /match-found HIT");

    // 1️⃣ Validate uploaded file
    if (!req.file) {
      return res.status(400).json({ message: "Photo required" });
    }

    const foundImagePath = path.resolve(req.file.path);

    // 2️⃣ Call AI service to extract embedding
    const extractRes = await axios.post(
      "http://127.0.0.1:5002/extract",
      { imagePath: foundImagePath },
      { timeout: 20000 }
    );

    const foundEmbedding = extractRes.data.embedding;

    if (!foundEmbedding) {
      return res.status(500).json({ message: "Embedding extraction failed" });
    }

    // 3️⃣ Fetch all pending missing persons
    const missingPeople = await MissingPerson.find({ status: "pending" });
    console.log("🧠 MissingPeople length:", missingPeople.length);

    if (missingPeople.length === 0) {
      return res.json({ message: "No pending missing persons" });
    }

    // 4️⃣ Find best match
    let bestMatch = null;
    let bestScore = 0;

    for (const person of missingPeople) {
      if (!person.faceEmbedding || person.faceEmbedding.length === 0) continue;

      const matchRes = await axios.post(
        "http://127.0.0.1:5002/match",
        {
          embedding1: person.faceEmbedding,
          embedding2: foundEmbedding,
        },
        { timeout: 10000 }
      );

      console.log(
        "🔍 Comparing with:",
        person._id.toString(),
        "Similarity:",
        matchRes.data.similarity
      );

      if (matchRes.data.similarity > bestScore) {
        bestScore = matchRes.data.similarity;
        bestMatch = person;
      }
    }

    console.log("🏆 Best score:", bestScore);

    // 5️⃣ If strong match found
    if (bestScore >= 0.6 && bestMatch) {
      console.log("✅ MATCH CONDITION PASSED for:", bestMatch._id.toString());

      // 5.1 Update missing person status
      bestMatch.status = "matched";
      await bestMatch.save();

      // 5.2 Save match result
      const match = await MatchResult.create({
        personA: bestMatch._id,
        personB: null,
        distance: 1 - bestScore,
        verified: false,
      });

      console.log("🟢 MatchResult saved:", match._id.toString());

      // 5.3 SAFETY CHECK: Ensure userId exists
      if (!bestMatch.registeredBy) {
        console.error(
          "❌ registeredBy is NULL for missing person:",
          bestMatch._id.toString()
        );

        return res.json({
          message:
            "Match found but cannot notify user (registeredBy missing)",
          similarity: bestScore,
          matchId: match._id,
          missingPersonId: bestMatch._id,
        });
      }

      // 5.4 Create notification (FIXED)
      const notification = await Notification.create({
        userId: bestMatch.registeredBy,
        title: "Possible Match Found",
        message: `A strong match was found for ${
          bestMatch.name
        } (Similarity: ${(bestScore * 100).toFixed(2)}%)`,
        relatedMissingPerson: bestMatch._id,
        isRead: false,
      });

      console.log(
        "🔔 Notification created for user:",
        bestMatch.registeredBy.toString(),
        "Notification ID:",
        notification._id.toString()
      );

      return res.json({
        message: "Match found and notification sent",
        similarity: bestScore,
        matchId: match._id,
        missingPersonId: bestMatch._id,
        notificationId: notification._id,
      });
    }

    // 6️⃣ No strong match
    return res.json({
      message: "No strong match found",
      similarity: bestScore,
    });
  } catch (err) {
    console.error("❌ MATCH ERROR:", err);
    return res.status(500).json({ error: err.message });
  }
});

export default router;
