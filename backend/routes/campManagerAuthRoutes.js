import express from "express";
import CampManager from "../models/CampManager.js";

const router = express.Router();

// DISABLED: Public registration removed - only admin can create camps
/*
// Register new camp manager
router.post("/register", async (req, res) => {
    try {
        const { campName, managerName, email, password, location, contactNumber } = req.body;

        // Check if email already exists
        const existingManager = await CampManager.findOne({ email });
        if (existingManager) {
            return res.status(400).json({ message: "Email already registered" });
        }

        // Generate unique campId
        const count = await CampManager.countDocuments();
        const campId = `CAMP${String(count + 1).padStart(3, "0")}`; // CAMP001, CAMP002, etc.

        // Create new camp manager
        const campManager = await CampManager.create({
            campId,
            campName,
            managerName,
            email,
            password, // TODO: Hash password in production
            location,
            contactNumber,
        });

        res.status(201).json({
            message: "Camp registered successfully",
            campId: campManager.campId,
            campName: campManager.campName,
        });
    } catch (error) {
        console.error("Registration error:", error);
        res.status(500).json({ message: "Registration failed", error: error.message });
    }
});
*/

// Login camp manager
router.post("/login", async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find camp manager by email
        const campManager = await CampManager.findOne({ email });

        if (!campManager) {
            return res.status(401).json({ message: "Invalid email or password" });
        }

        // Check password (plain text comparison for now)
        if (campManager.password !== password) {
            return res.status(401).json({ message: "Invalid email or password" });
        }

        // Return camp manager details
        res.json({
            message: "Login successful",
            campId: campManager.campId,
            campName: campManager.campName,
            managerName: campManager.managerName,
            email: campManager.email,
            location: campManager.location,
            contactNumber: campManager.contactNumber,
        });
    } catch (error) {
        console.error("Login error:", error);
        res.status(500).json({ message: "Login failed", error: error.message });
    }
});

// Get camp profile
router.get("/profile/:campId", async (req, res) => {
    try {
        const campManager = await CampManager.findOne({ campId: req.params.campId });

        if (!campManager) {
            return res.status(404).json({ message: "Camp not found" });
        }

        res.json({
            campId: campManager.campId,
            campName: campManager.campName,
            managerName: campManager.managerName,
            email: campManager.email,
            location: campManager.location,
            contactNumber: campManager.contactNumber,
        });
    } catch (error) {
        console.error("Profile fetch error:", error);
        res.status(500).json({ message: "Failed to fetch profile" });
    }
});

export default router;
