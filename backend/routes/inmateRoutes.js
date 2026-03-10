import express from "express";
import CampInmate from "../models/CampInmate.js";

const router = express.Router();

// Register new inmate
router.post("/register", async (req, res) => {
    try {
        const inmate = await CampInmate.create(req.body);
        res.json({ message: "Inmate registered successfully", inmate });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get all inmates for a camp
router.get("/:campId", async (req, res) => {
    try {
        const { campId } = req.params;
        const inmates = await CampInmate.find({ campId }).sort({ registeredAt: -1 });
        res.json(inmates);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get statistics for a camp
router.get("/:campId/stats", async (req, res) => {
    try {
        const { campId } = req.params;

        const total = await CampInmate.countDocuments({ campId, status: "Active" });
        const maleCount = await CampInmate.countDocuments({ campId, status: "Active", gender: "Male" });
        const femaleCount = await CampInmate.countDocuments({ campId, status: "Active", gender: "Female" });
        const otherCount = await CampInmate.countDocuments({ campId, status: "Active", gender: "Other" });

        // Age groups
        const inmates = await CampInmate.find({ campId, status: "Active" });
        const ageGroups = {
            "0-18": 0,
            "19-35": 0,
            "36-60": 0,
            "60+": 0
        };

        inmates.forEach(inmate => {
            if (inmate.age <= 18) ageGroups["0-18"]++;
            else if (inmate.age <= 35) ageGroups["19-35"]++;
            else if (inmate.age <= 60) ageGroups["36-60"]++;
            else ageGroups["60+"]++;
        });

        res.json({
            total,
            byGender: { male: maleCount, female: femaleCount, other: otherCount },
            byAge: ageGroups
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Update inmate
router.put("/:inmateId", async (req, res) => {
    try {
        const { inmateId } = req.params;
        const inmate = await CampInmate.findByIdAndUpdate(inmateId, req.body, { new: true });
        res.json({ message: "Inmate updated successfully", inmate });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Delete inmate
router.delete("/:inmateId", async (req, res) => {
    try {
        const { inmateId } = req.params;
        await CampInmate.findByIdAndDelete(inmateId);
        res.json({ message: "Inmate deleted successfully" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

export default router;

