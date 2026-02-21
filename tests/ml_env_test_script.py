import logging
import os
import sys
import json
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

# Container detection
def detect_container():
    """Detect if running in Docker or Singularity"""
    in_docker = os.path.exists('/.dockerenv')
    in_singularity = 'SINGULARITY_CONTAINER' in os.environ
    return in_docker, in_singularity

in_docker, in_singularity = detect_container()
container_type = "Docker" if in_docker else ("Singularity" if in_singularity else "Host")

# Results tracking
results = {
    "container": container_type,
    "hostname": os.uname().nodename,
    "tests": {}
}

logging.info("=" * 60)
logging.info("Machine Learning Environment Test")
logging.info(f"Running in: {container_type}")
logging.info("=" * 60)

# Report environment
logging.info("\n--- Environment Info ---")
logging.info(f"Python: {sys.version}")
logging.info(f"PyTorch: {torch.__version__}")
logging.info(f"TensorFlow: {tf.__version__}")
logging.info(f"JAX: {jax.__version__}")
logging.info(f"cuDF: {cudf.__version__}")
logging.info(f"cugraph: {cugraph.__version__}")
logging.info(f"LightGBM: {__import__('lightgbm').__version__}")
logging.info(f"Pandas: {pd.__version__}")
logging.info(f"NumPy: {np.__version__}")
logging.info(f"UMAP: {umap.__version__}")

# Helper function to run tests with error handling
def run_test(name, func):
    logging.info(f"\n--- {name} ---")
    try:
        func()
        logging.info(f"✅ {name} passed.")
        results["tests"][name] = {"status": "passed"}
        return True
    except Exception as e:
        logging.error(f"❌ {name} failed: {str(e)}")
        results["tests"][name] = {"status": "failed", "error": str(e)}
        return False

# CUDA & GPU Availability
def test_cuda():
    """Test GPU/CUDA availability across frameworks"""
    cuda_available = torch.cuda.is_available()
    gpu_count = torch.cuda.device_count()
    tf_gpus = tf.config.list_physical_devices('GPU')
    jax_devices = jax.devices()
    
    logging.info(f"PyTorch CUDA available: {cuda_available}")
    logging.info(f"PyTorch GPU count: {gpu_count}")
    logging.info(f"TensorFlow GPUs: {len(tf_gpus)}")
    logging.info(f"JAX devices: {jax_devices}")
    
    # Store results
    results["tests"]["CUDA"] = {
        "pytorch_cuda": cuda_available,
        "gpu_count": gpu_count,
        "tf_gpus": len(tf_gpus),
        "jax_devices": str(jax_devices)
    }

# PyTorch Test
def test_pytorch():
    """Test PyTorch forward pass"""
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logging.info(f"Using device: {device}")
    
    import torch.nn as nn
    model = nn.Sequential(nn.Linear(10, 5), nn.ReLU(), nn.Linear(5, 2)).to(device)
    
    inp = torch.randn(1, 10, device=device)
    output = model(inp)
    logging.info(f"Forward pass successful. Output shape: {output.shape}, device: {output.device}")

# TensorFlow Test
def test_tensorflow():
    """Test TensorFlow model training"""
    model = tf.keras.Sequential([
        tf.keras.layers.Dense(10, activation='relu'),
        tf.keras.layers.Dense(1)
    ])
    model.compile(optimizer='adam', loss='mse')
    
    # Small dataset for quick test
    x = tf.random.normal((10, 5))
    y = tf.random.normal((10, 1))
    
    history = model.fit(x, y, epochs=1, verbose=0)
    logging.info(f"Training completed. Loss: {history.history['loss'][0]:.4f}")

# JAX Test
def test_jax():
    """Test JAX gradient computation"""
    def f(x):
        return x ** 2 + 3 * x + 2
    
    grad_f = grad(f)
    grad_val = grad_f(2.0)
    logging.info(f"Gradient at x=2.0: {grad_val}")
    
    # Also test JIT compilation
    jit_f = jax.jit(f)
    jit_val = jit_f(3.0)
    logging.info(f"JIT compiled result at x=3.0: {jit_val}")

# RAPIDS cuGraph Test
def test_cugraph():
    """Test RAPIDS cuGraph"""
    df = cudf.DataFrame({'src': [0, 1, 2], 'dst': [1, 2, 0]})
    G = cugraph.Graph()
    G.from_cudf_edgelist(df, source='src', destination='dst')
    pr = cugraph.pagerank(G)
    logging.info(f"PageRank computation successful. Result shape: {pr.shape}")

# LightGBM Test
def test_lightgbm():
    """Test LightGBM training"""
    X = np.random.rand(100, 10)
    y = np.random.rand(100)
    model = LGBMRegressor(n_estimators=10, verbose=-1)
    model.fit(X, y)
    preds = model.predict(X[:5])
    logging.info(f"LightGBM training successful. Predictions: {preds[:3]}")

# Prophet Test
def test_prophet():
    """Test Prophet time series forecasting"""
    try:
        from prophet import Prophet
        df = pd.DataFrame({
            'ds': pd.date_range(start='2023-01-01', periods=100),
            'y': np.random.rand(100) + np.arange(100) * 0.01  # Slight trend
        })
        model = Prophet(interval_width=0.95, yearly_seasonality=False, daily_seasonality=False)
        with logging.getLogger('cmdstanpy').disabled:
            model.fit(df)
        future = model.make_future_dataframe(periods=10)
        forecast = model.predict(future)
        logging.info(f"Prophet forecast successful. Forecast period: {forecast[['ds', 'yhat']].tail(1).values}")
    except ImportError as e:
        logging.warning(f"Prophet not available: {e}")
        raise

# UMAP Test
def test_umap():
    """Test UMAP dimensionality reduction"""
    X = np.random.rand(100, 10)
    reducer = umap.UMAP(n_components=2, n_neighbors=5, min_dist=0.1, verbose=0)
    embedding = reducer.fit_transform(X)
    logging.info(f"UMAP embedding successful. Output shape: {embedding.shape}")

# Seaborn Visualization Test
def test_seaborn():
    """Test Seaborn visualization (no display)"""
    plt.figure()
    sns.histplot([1, 2, 2, 3, 4, 5, 5, 5, 6])
    plt.savefig("seaborn_test_plot.png", dpi=100, bbox_inches='tight')
    plt.close()
    logging.info("Seaborn plot saved as seaborn_test_plot.png")

# CatBoost Test
def test_catboost():
    """Test CatBoost training"""
    try:
        from catboost import CatBoostRegressor
        X = np.random.rand(100, 10)
        y = np.random.rand(100)
        model = CatBoostRegressor(iterations=10, verbose=False)
        model.fit(X, y)
        preds = model.predict(X[:5])
        logging.info(f"CatBoost training successful. Predictions: {preds[:3]}")
    except ImportError as e:
        logging.warning(f"CatBoost not available: {e}")
        raise

# Run all tests
logging.info("\n" + "=" * 60)
logging.info("Running Framework Tests")
logging.info("=" * 60)

run_test("CUDA & GPU Availability", test_cuda)
run_test("PyTorch", test_pytorch)
run_test("TensorFlow", test_tensorflow)
run_test("JAX", test_jax)
run_test("RAPIDS cuGraph", test_cugraph)
run_test("LightGBM", test_lightgbm)
run_test("Prophet", test_prophet)
run_test("UMAP", test_umap)
run_test("Seaborn", test_seaborn)
run_test("CatBoost", test_catboost)

# Summary
logging.info("\n" + "=" * 60)
passed = sum(1 for t in results["tests"].values() if t.get("status") == "passed")
failed = sum(1 for t in results["tests"].values() if t.get("status") == "failed")
logging.info(f"Test Summary: {passed} passed, {failed} failed out of {len(results['tests'])} tests")
logging.info("=" * 60)

# Save JSON results
with open("ml_env_test_results.json", "w") as f:
    json.dump(results, f, indent=2, default=str)
logging.info("Results saved to ml_env_test_results.json")

# Exit with error code if any tests failed
sys.exit(0 if failed == 0 else 1)