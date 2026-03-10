from flask import Flask
from routes.missing_person import missing_bp
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

app.register_blueprint(missing_bp, url_prefix="/api")

app.run(debug=True)
