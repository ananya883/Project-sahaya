import mongoose from "mongoose";

const matchSchema = new mongoose.Schema(
  {
    missingPerson: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "MissingPerson",
      required: true,
      index: true,
    },

    unknownPerson: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "UnknownPerson",
      required: true,
      index: true,
    },

    similarity: {
      type: Number,
      required: true,
      min: 0,
      max: 1,
    },

    confidenceLevel: {
      type: String,
      enum: ["low", "medium", "high"],
      required: true,
    },

    status: {
      type: String,
      enum: ["pending", "verified", "rejected"],
      default: "pending",
      index: true,
    },

    verifiedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    verifiedAt: {
      type: Date,
    },
  },
  { timestamps: true }
);

// Prevent duplicate matches
matchSchema.index(
  { missingPerson: 1, unknownPerson: 1 },
  { unique: true }
);

export default mongoose.model("Match", matchSchema);
