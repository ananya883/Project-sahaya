// routes/sosRoutes.js
import express from "express";
import multer from "multer";
import path from "path";
import SOS from "../models/sos.js"; // Make sure SOS schema exists

const router = express.Router();

// ---------- Multer Configuration for Media Upload ----------
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/"); // Make sure this folder exists
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}${path.extname(file.originalname)}`);
  },
});

const upload = multer({ storage });

// ---------- POST /api/sos ----------
router.post("/", upload.single("image"), async (req, res) => {
  try {
    const { emergency_type, disaster_type, latitude, longitude, timestamp } = req.body;

    const image_url = req.file
      ? `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`
      : "";

    const newSos = new SOS({
      emergency_type,
      disaster_type,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      image_url,
    });

    await newSos.save();

    res.status(201).json({
      success: true,
      message: "SOS stored successfully",
      sos: newSos,
    });
  } catch (err) {
    console.error("❌ SOS Save Error:", err);
    res.status(500).json({ success: false, message: "Server Error", error: err.message });
  }
});

// ---------- GET /api/sos ----------
router.get("/", async (req, res) => {
  try {
    const sosList = await SOS.find().sort({ timestamp: -1 });
    res.status(200).json(sosList);
  } catch (err) {
    console.error("❌ SOS Fetch Error:", err);
    res.status(500).json({ message: "Failed to fetch SOS reports", error: err.message });
  }
});

export default router;
