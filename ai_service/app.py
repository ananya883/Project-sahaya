from flask import Flask, request, jsonify
from facenet_pytorch import MTCNN, InceptionResnetV1
from PIL import Image
import torch
import numpy as np
import os
from numpy.linalg import norm

app = Flask(__name__)

# -----------------------------
# Load Face Detection & FaceNet
# -----------------------------
# MTCNN for face detection + alignment
mtcnn = MTCNN(
    image_size=160,
    margin=20,
    select_largest=True,
    post_process=True
)

# FaceNet model (128-D embedding)
facenet = InceptionResnetV1(
    pretrained='vggface2'
).eval()

# -----------------------------
# Utility: Extract FaceNet Embedding
# -----------------------------
def extract_facenet_embedding(image_path):
    """
    Takes image path
    Returns 128-D embedding or None
    """
    try:
        img = Image.open(image_path).convert('RGB')
    except Exception:
        return None

    face = mtcnn(img)

    if face is None:
        return None

    with torch.no_grad():
        embedding = facenet(face.unsqueeze(0))

    return embedding[0].numpy()


# -----------------------------
# Utility: Cosine Similarity
# -----------------------------
def cosine_similarity(vec1, vec2):
    return np.dot(vec1, vec2) / (norm(vec1) * norm(vec2))


# -----------------------------
# API: Extract Embedding
# -----------------------------
@app.route('/extract', methods=['POST'])
def extract():
    # Check for file upl  oad (multipart/form-data)
    if 'image' in request.files:
        print("📸 [AI] Received image file upload", flush=True)
        image_file = request.files['image']
        temp_path = "temp_image.jpg"
        image_file.save(temp_path)
        
        try:
            print(f"🔄 [AI] Processing image from {temp_path}...", flush=True)
            embedding = extract_facenet_embedding(temp_path)
            print("✅ [AI] Embedding extraction complete (file)", flush=True)
        except Exception as e:
             print(f"❌ [AI] Error processing file: {e}", flush=True)
             embedding = None
        finally:
             if os.path.exists(temp_path):
                 os.remove(temp_path)
                 
    # Check for JSON body (application/json)
    elif request.is_json and 'imagePath' in request.get_json():
        data = request.get_json()
        image_path = data['imagePath']
        print(f"📸 [AI] Received image path: {image_path}", flush=True)
        
        if not os.path.exists(image_path):
             print(f"❌ [AI] File not found: {image_path}", flush=True)
             return jsonify({"error": f"File not found at {image_path}"}), 400
             
        embedding = extract_facenet_embedding(image_path)
        print("✅ [AI] Embedding extraction complete (path)", flush=True)
        
    else:
        print("⚠️ [AI] No image provided in request", flush=True)
        return jsonify({"error": "No image file or imagePath provided"}), 400

    if embedding is None:
        print("⚠️ [AI] No face detected or extraction failed", flush=True)
        return jsonify({"error": "No face detected"}), 400

    return jsonify({
        "embedding": embedding.tolist()
    })


# -----------------------------
# API: Match Two Faces
# -----------------------------
@app.route('/match', methods=['POST'])
def match():
    print("🤝 [AI] Match request received", flush=True)
    data = request.get_json()

    if not data or 'embedding1' not in data or 'embedding2' not in data:
        print("❌ [AI] Invalid match input (missing embeddings)", flush=True)
        return jsonify({"error": "Invalid input"}), 400

    try:
        emb1 = np.array(data['embedding1'])
        emb2 = np.array(data['embedding2'])

        similarity = cosine_similarity(emb1, emb2)
        print(f"🔍 [AI] Similarity calculated: {similarity}", flush=True)

        # Thresholds (can be tuned)
        if similarity >= 0.85:
            result = "Strong Match"
        elif similarity >= 0.75:
            result = "Possible Match"
        else:
            result = "No Match"
        
        return jsonify({
            "similarity": float(similarity),
            "result": result
        })
    except Exception as e:
        print(f"❌ [AI] Match error: {e}", flush=True)
        return jsonify({"error": str(e)}), 500


# -----------------------------
# Run Server
# -----------------------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=True)
