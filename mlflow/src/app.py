from flask import Flask, request, jsonify
import mlflow.sklearn
import pandas as pd
import os

app = Flask(__name__)

# Load the latest model from MLflow registry (optional)
def load_latest_model():
    try:
        mlflow_tracking_uri = os.getenv('MLFLOW_TRACKING_URI', 'file:./models/mlruns')
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        model = mlflow.sklearn.load_model("models:/latest_model/Production")
        print("Successfully loaded model: latest_model")
        return model
    except Exception as e:
        print(f"Warning: Could not load model 'latest_model': {e}")
        print("MLflow service will start without a loaded model")
        return None

model = load_latest_model()

@app.route('/predict', methods=['POST'])
def predict():
    try:
        if model is None:
            return jsonify({'error': 'No model loaded. Please train and register a model first.'}), 503
        
        data = request.get_json()
        # Assume data is a list of feature lists
        df = pd.DataFrame(data)
        predictions = model.predict(df)
        return jsonify({'predictions': predictions.tolist()})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)