import mongoose from "mongoose";

const missingPersonSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    age: Number,
    gender: String,
    height: String,
    weight: String,
    birthmark: String,

    lastSeenLocation: String,
    lastSeenDate: Date,

    imagePath: { type: String, required: true },

    faceEmbedding: {
      type: [Number],
      required: false, // Changed to false to prevent save failure on AI timeout
    },

    registeredBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    status: {
      type: String,
      enum: ["missing", "found"],
      default: "missing",
    },

    matchedUnknown: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "UnknownPerson",
      default: null,
    },
  },
  { timestamps: true }
);

export default mongoose.model("MissingPerson", missingPersonSchema);
