import logging
import os
import torch
import tensorflow as tf
import jax
import jax.numpy as jnp
from jax import grad
import seaborn as sns
import matplotlib.pyplot as plt
from lightgbm import LGBMRegressor
import numpy as np
import pandas as pd
import cudf
import cugraph
import umap

# Setup logging
log_file = "ml_env_test.log"
logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

console = logging.StreamHandler()
console.setLevel(logging.INFO)
formatter = logging.Formatter('%(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)

logging.info("=== Machine Learning Environment Test ===")

# Helper function to run tests with error handling
def run_test(name, func):
    logging.info(f"--- {name} ---")
    try:
        func()
        logging.info(f"{name} passed. ✅")
    except Exception as e:
        logging.error(f"{name} failed. ❌ Error: {e}")

# CUDA & GPU Availability
def test_cuda():
    logging.info(f"PyTorch CUDA available: {torch.cuda.is_available()}")
    logging.info(f"PyTorch GPU count: {torch.cuda.device_count()}")
    logging.info(f"TensorFlow GPU available: {tf.config.list_physical_devices('GPU')}")
    logging.info(f"JAX devices: {jax.devices()}")

# PyTorch Test
def test_pytorch():
    import torch.nn as nn
    from torchinfo import summary
    model = nn.Sequential(nn.Linear(10, 5), nn.ReLU(), nn.Linear(5, 2))
    summary(model, input_size=(1, 10))
    output = model(torch.randn(1, 10))
    logging.info(f"Forward pass output: {output}")

# TensorFlow Test
def test_tensorflow():
    model = tf.keras.Sequential([
        tf.keras.layers.Dense(10, activation='relu'),
        tf.keras.layers.Dense(1)
    ])
    model.compile(optimizer='adam', loss='mse')
    model.fit(tf.random.normal((10, 5)), tf.random.normal((10, 1)), epochs=1)

# JAX Test
def test_jax():
    def f(x):
        return x ** 2 + 3 * x + 2
    grad_val = grad(f)(2.0)
    logging.info(f"Gradient at x=2: {grad_val}")

# RAPIDS cuGraph Test
def test_cugraph():
    df = cudf.DataFrame({'src': [0, 1, 2], 'dst': [1, 2, 0]})
    G = cugraph.Graph()
    G.from_cudf_edgelist(df, source='src', destination='dst')
    pr = cugraph.pagerank(G)
    logging.info(f"PageRank result:{pr}")

# LightGBM Test
def test_lightgbm():
    X = np.random.rand(100, 10)
    y = np.random.rand(100)
    model = LGBMRegressor()
    model.fit(X, y)
    preds = model.predict(X[:5])
    logging.info(f"LightGBM Predictions: {preds}")

# Prophet Test
def test_prophet():
    try:
        from prophet import Prophet
        df = pd.DataFrame({
            'ds': pd.date_range(start='2023-01-01', periods=100),
            'y': np.random.rand(100)
        })
        model = Prophet()
        model.fit(df)
        future = model.make_future_dataframe(periods=10)
        forecast = model.predict(future)
        logging.info(f"Prophet forecast tail:{forecast[['ds', 'yhat']].tail()}")
    except ModuleNotFoundError:
        logging.warning("Prophet is not installed. Please install it with 'conda install -c conda-forge prophet' or 'pip install prophet'.")

# UMAP Test
def test_umap():
    X = np.random.rand(100, 10)
    reducer = umap.UMAP()
    embedding = reducer.fit_transform(X)
    logging.info(f"UMAP embedding shape: {embedding.shape}")

# Seaborn Visualization Test
def test_seaborn():
    sns.histplot([1, 2, 2, 3, 4])
    plt.savefig("seaborn_test_plot.png")
    logging.info("Seaborn plot saved as seaborn_test_plot.png")

# CatBoost Test
def test_catboost():
    try:
        from catboost import CatBoostRegressor
        X = np.random.rand(100, 10)
        y = np.random.rand(100)
        model = CatBoostRegressor(verbose=0)
        model.fit(X, y)
        preds = model.predict(X[:5])
        logging.info(f"CatBoost Predictions: {preds}")
    except ModuleNotFoundError:
        logging.warning("CatBoost is not installed. Please install it with 'conda install -c conda-forge catboost' or 'pip install catboost'.")

# Run all tests
run_test("CUDA & GPU Availability", test_cuda)
run_test("PyTorch Test", test_pytorch)
run_test("TensorFlow Test", test_tensorflow)
run_test("JAX Test", test_jax)
run_test("RAPIDS cuGraph Test", test_cugraph)
run_test("LightGBM Test", test_lightgbm)
run_test("Prophet Test", test_prophet)
run_test("UMAP Test", test_umap)
run_test("Seaborn Visualization Test", test_seaborn)
run_test("CatBoost Test", test_catboost)

logging.info("=== Test Completed. See 'ml_env_test.log' for details. ===")