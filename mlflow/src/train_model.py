import mlflow
import mlflow.sklearn
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
import pandas as pd
from hive_data_fetcher import fetch_training_data
import os

def train_model():
    """
    Train a machine learning model using data from Hive and log to MLflow.
    """
    # Set MLflow tracking URI if needed
    mlflow_tracking_uri = os.getenv('MLFLOW_TRACKING_URI', 'file:./models/mlruns')
    mlflow.set_tracking_uri(mlflow_tracking_uri)

    # Fetch data
    df = fetch_training_data()

    # Assume the data has columns 'features' and 'target'
    # For simplicity, assume df has multiple columns, last is target
    X = df.iloc[:, :-1]
    y = df.iloc[:, -1]

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train model
    model = LinearRegression()
    model.fit(X_train, y_train)

    # Predict and evaluate
    predictions = model.predict(X_test)
    mse = mean_squared_error(y_test, predictions)

    # Log to MLflow
    with mlflow.start_run():
        mlflow.log_param("model_type", "LinearRegression")
        mlflow.log_metric("mse", mse)
        mlflow.sklearn.log_model(model, "model")

        # Register the model
        model_uri = f"runs:/{mlflow.active_run().info.run_id}/model"
        mlflow.register_model(model_uri, "latest_model")

    print(f"Model trained and registered with MSE: {mse}")

if __name__ == "__main__":
    train_model()