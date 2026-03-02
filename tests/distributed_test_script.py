#!/usr/bin/env python3
"""
Distributed Computing Test for Container Environments
Tests Dask, PyTorch, TensorFlow, and Ray in single-container context
Designed for both development and CI/CD pipelines
"""

import os
import sys
import json
import logging
import torch
import tensorflow as tf
from pathlib import Path

try:
    import dask
    from dask import delayed, compute
    from dask.distributed import Client 
    from dask_cuda import LocalCUDACluster

    HAS_DASK = True
except ImportError:
    HAS_DASK = False

try:
    import ray
    HAS_RAY = True
except ImportError:
    HAS_RAY = False

try:
    import horovod.torch as hvd
    HAS_HOROVOD = True
except ImportError:
    HAS_HOROVOD = False

# Setup logging
log_file = "test-results/distributed_test.log"
logging.basicConfig(
    filename=log_file,
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
console = logging.StreamHandler()
console.setLevel(logging.INFO)
formatter = logging.Formatter('%(levelname)s: %(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)

# ============================================================================
# Container Detection
# ============================================================================

def detect_container():
    """Detect if running in Docker, Singularity, or native environment"""
    in_docker = os.path.exists('/.dockerenv')
    in_singularity = 'SINGULARITY_CONTAINER' in os.environ
    
    if in_docker:
        return "Docker"
    elif in_singularity:
        return "Singularity"
    else:
        return "Host"

# ============================================================================
# Environment Information
# ============================================================================

def get_environment_info():
    """Gather environment and hardware information"""
    info = {
        "container": detect_container(),
        "hostname": os.uname().nodename,
        "gpu_count": torch.cuda.device_count(),
        "cuda_available": torch.cuda.is_available(),
        "cuda_version": torch.version.cuda if torch.cuda.is_available() else None,
        "pytorch_version": torch.__version__,
        "tensorflow_version": tf.__version__,
        "dask_available": HAS_DASK,
        "ray_available": HAS_RAY,
        "horovod_available": HAS_HOROVOD
    }
    
    if torch.cuda.is_available():
        info["gpu_name"] = torch.cuda.get_device_name(0)
    
    logging.info(f"Environment: {info['container']}")
    logging.info(f"GPUs available: {info['gpu_count']}")
    logging.info(f"CUDA available: {info['cuda_available']}")
    
    return info

# ============================================================================
# Dask Tests
# ============================================================================

def test_dask_basic():
    """Test basic Dask delayed computation"""
    if not HAS_DASK:
        logging.warning("Dask not installed, skipping Dask tests")
        return {"status": "skipped", "reason": "Dask not installed"}
    
    try:
        logging.info("Starting Dask LocalCluster (2 workers, 1 thread each)...")
        cluster = LocalCUDACluster(n_workers=2, threads_per_worker=1, silence_logs=False)
        client = Client(cluster)
        
        @delayed
        def square(x):
            return x * x
        
        @delayed
        def add(x, y):
            return x + y
        
        # Create computation graph
        a = square(4)
        b = square(5)
        c = add(a, b)
        
        result = c.compute()
        expected = 41  # (4^2) + (5^2) = 16 + 25 = 41
        
        logging.info(f"Dask computation result: {result} (expected: {expected})")
        
        if result == expected:
            client.close()
            cluster.close()
            return {"status": "passed", "result": int(result)}
        else:
            client.close()
            cluster.close()
            return {"status": "failed", "reason": f"Expected {expected}, got {result}"}
    
    except Exception as e:
        logging.error(f"Dask test failed: {e}")
        try:
            client.close()
            cluster.close()
        except:
            pass
        return {"status": "failed", "reason": str(e)}

def test_dask_distributed_array():
    """Test Dask distributed arrays"""
    if not HAS_DASK:
        return {"status": "skipped", "reason": "Dask not installed"}
    
    try:
        import dask.array as da
        
        logging.info("Testing Dask distributed arrays...")
        cluster = LocalCUDACluster(n_workers=2, threads_per_worker=1, silence_logs=False)
        client = Client(cluster)
        
        # Create distributed array and compute sum
        x = da.from_delayed(__import__('dask').delayed(lambda: [1, 2, 3, 4, 5])(), shape=(5,), dtype=int)
        result = x.sum().compute()
        expected = 15
        
        logging.info(f"Dask array sum: {result} (expected: {expected})")
        
        client.close()
        cluster.close()
        
        return {"status": "passed", "result": int(result)} if result == expected else {"status": "failed", "reason": f"Expected {expected}, got {result}"}
    
    except Exception as e:
        logging.error(f"Dask array test failed: {e}")
        try:
            client.close()
            cluster.close()
        except:
            pass
        return {"status": "failed", "reason": str(e)}

# ============================================================================
# PyTorch Single-GPU Tests (No DDP)
# ============================================================================

def test_pytorch_single_gpu():
    """Test PyTorch single-GPU forward pass"""
    try:
        if not torch.cuda.is_available():
            logging.warning("CUDA not available, running on CPU")
            device = torch.device("cpu")
        else:
            device = torch.device("cuda:0")
        
        logging.info(f"PyTorch testing on device: {device}")
        
        # Create model and move to device
        model = torch.nn.Sequential(
            torch.nn.Linear(10, 64),
            torch.nn.ReLU(),
            torch.nn.Linear(64, 1)
        ).to(device)
        
        # Create input and forward pass
        x = torch.randn(32, 10).to(device)
        y = model(x)
        
        logging.info(f"PyTorch forward pass successful, output shape: {y.shape}")
        return {"status": "passed", "device": str(device), "output_shape": list(y.shape)}
    
    except Exception as e:
        logging.error(f"PyTorch single-GPU test failed: {e}")
        return {"status": "failed", "reason": str(e)}

def test_pytorch_backward():
    """Test PyTorch backward pass and gradient computation"""
    try:
        if not torch.cuda.is_available():
            device = torch.device("cpu")
        else:
            device = torch.device("cuda:0")
        
        logging.info("Testing PyTorch backward pass...")
        
        model = torch.nn.Linear(5, 3).to(device)
        optimizer = torch.optim.SGD(model.parameters(), lr=0.01)
        
        x = torch.randn(10, 5, requires_grad=True).to(device)
        y_target = torch.randn(10, 3).to(device)
        
        # Forward pass
        y_pred = model(x)
        loss = torch.nn.functional.mse_loss(y_pred, y_target)
        
        # Backward pass
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        logging.info(f"PyTorch backward pass successful, loss: {loss.item():.4f}")
        return {"status": "passed", "loss": float(loss.item())}
    
    except Exception as e:
        logging.error(f"PyTorch backward test failed: {e}")
        return {"status": "failed", "reason": str(e)}

# ============================================================================
# TensorFlow Single-GPU Tests
# ============================================================================

def test_tensorflow_basic():
    """Test TensorFlow basic training"""
    try:
        logging.info("Testing TensorFlow basic training...")
        
        # Set memory growth to avoid GPU memory issues
        gpus = tf.config.list_physical_devices('GPU')
        for gpu in gpus:
            try:
                tf.config.experimental.set_memory_growth(gpu, True)
            except RuntimeError:
                pass
        
        # Simple model training
        model = tf.keras.Sequential([
            tf.keras.layers.Dense(64, activation='relu', input_shape=(10,)),
            tf.keras.layers.Dense(1)
        ])
        
        model.compile(optimizer='adam', loss='mse')
        
        # Generate dummy data
        x = tf.random.normal((100, 10))
        y = tf.random.normal((100, 1))
        
        # Train for 1 epoch
        history = model.fit(x, y, epochs=1, verbose=0)
        
        logging.info(f"TensorFlow training successful, loss: {history.history['loss'][0]:.4f}")
        return {"status": "passed", "loss": float(history.history['loss'][0])}
    
    except Exception as e:
        logging.error(f"TensorFlow basic test failed: {e}")
        return {"status": "failed", "reason": str(e)}

def test_tensorflow_mirrored_strategy():
    """Test TensorFlow MirroredStrategy (auto-detects available GPUs)"""
    try:
        logging.info("Testing TensorFlow MirroredStrategy...")
        
        gpus = tf.config.list_physical_devices('GPU')
        for gpu in gpus:
            try:
                tf.config.experimental.set_memory_growth(gpu, True)
            except RuntimeError:
                pass
        
        # MirroredStrategy auto-detects GPUs
        strategy = tf.distribute.MirroredStrategy()
        
        with strategy.scope():
            model = tf.keras.Sequential([
                tf.keras.layers.Dense(32, activation='relu', input_shape=(10,)),
                tf.keras.layers.Dense(1)
            ])
            model.compile(optimizer='adam', loss='mse')
        
        # Use batch size that's evenly divisible by number of GPUs
        batch_size = 64  # 32 per GPU with 2 GPUs
        x = tf.random.normal((128, 10))
        y = tf.random.normal((128, 1))
        
        history = model.fit(x, y, batch_size=batch_size, epochs=1, verbose=0)
        
        logging.info(f"TensorFlow MirroredStrategy successful, loss: {history.history['loss'][0]:.4f}")
        return {"status": "passed", "loss": float(history.history['loss'][0]), "devices": len(strategy.num_replicas_in_sync)}
    
    except Exception as e:
        logging.error(f"TensorFlow MirroredStrategy test failed: {e}")
        return {"status": "failed", "reason": str(e)}

# ============================================================================
# Ray Tests
# ============================================================================

def test_ray_basic():
    """Test Ray basic distributed computing"""
    if not HAS_RAY:
        logging.warning("Ray not installed, skipping Ray tests")
        return {"status": "skipped", "reason": "Ray not installed"}
    
    try:
        logging.info("Testing Ray basic distributed computing...")
        
        # Initialize Ray with limited resources
        if not ray.is_initialized():
            ray.init(ignore_reinit_error=True, num_cpus=2, num_gpus=torch.cuda.device_count() if torch.cuda.is_available() else 0)
        
        @ray.remote
        def square(x):
            return x * x
        
        # Submit tasks
        futures = [square.remote(i) for i in range(5)]
        results = ray.get(futures)
        expected = [0, 1, 4, 9, 16]
        
        logging.info(f"Ray results: {results}")
        
        ray.shutdown()
        
        return {"status": "passed", "results": results} if results == expected else {"status": "failed", "reason": f"Expected {expected}, got {results}"}
    
    except Exception as e:
        logging.error(f"Ray basic test failed: {e}")
        try:
            ray.shutdown()
        except:
            pass
        return {"status": "failed", "reason": str(e)}

# ============================================================================
# Horovod Tests
# ============================================================================

def test_horovod_pytorch():
    """Test Horovod with PyTorch (single-process)"""
    if not HAS_HOROVOD:
        logging.warning("Horovod not installed, skipping Horovod tests")
        return {"status": "skipped", "reason": "Horovod not installed"}
    
    try:
        logging.info("Testing Horovod with PyTorch...")
        
        hvd.init()
        
        if torch.cuda.is_available():
            torch.cuda.set_device(hvd.local_rank())
            device = torch.device("cuda")
        else:
            device = torch.device("cpu")
        
        model = torch.nn.Linear(10, 1).to(device)
        
        # Scale learning rate by number of workers
        optimizer = torch.optim.SGD(model.parameters(), lr=0.01 * hvd.size())
        
        # Wrap optimizer with Horovod DistributedOptimizer
        optimizer = hvd.DistributedOptimizer(optimizer)
        
        # Broadcast initial parameters
        hvd.broadcast_parameters(model.state_dict(), root_rank=0)
        hvd.broadcast_optimizer_state(optimizer, root_rank=0)
        
        logging.info(f"Horovod initialized: rank={hvd.rank()}, size={hvd.size()}")
        
        hvd.shutdown()
        return {"status": "passed", "rank": hvd.rank(), "size": hvd.size()}
    
    except Exception as e:
        logging.error(f"Horovod PyTorch test failed: {e}")
        try:
            hvd.shutdown()
        except:
            pass
        return {"status": "failed", "reason": str(e)}

# ============================================================================
# Main Execution
# ============================================================================

def main():
    """Run all distributed tests"""
    logging.info("=" * 70)
    logging.info("DISTRIBUTED COMPUTING TEST SUITE")
    logging.info("=" * 70)
    
    # Gather environment info
    env_info = get_environment_info()
    
    # Test results
    results = {
        "environment": env_info,
        "tests": {}
    }
    
    # Run tests
    test_cases = [
        ("Dask Basic Computation", test_dask_basic),
        ("Dask Distributed Arrays", test_dask_distributed_array),
        ("PyTorch Single-GPU Forward", test_pytorch_single_gpu),
        ("PyTorch Backward Pass", test_pytorch_backward),
        ("TensorFlow Basic Training", test_tensorflow_basic),
        # ("TensorFlow MirroredStrategy", test_tensorflow_mirrored_strategy),
        ("Ray Basic Distributed", test_ray_basic),
    ]
    
    passed = 0
    failed = 0
    skipped = 0
    
    for test_name, test_func in test_cases:
        logging.info(f"\n--- {test_name} ---")
        result = test_func()
        results["tests"][test_name] = result
        
        status = result.get("status", "unknown")
        if status == "passed":
            logging.info(f"✅ {test_name} PASSED")
            passed += 1
        elif status == "failed":
            logging.error(f"❌ {test_name} FAILED: {result.get('reason', 'Unknown error')}")
            failed += 1
        else:
            logging.warning(f"⊘ {test_name} SKIPPED: {result.get('reason', 'Unknown')}")
            skipped += 1
    
    # Summary
    logging.info("\n" + "=" * 70)
    logging.info(f"TEST SUMMARY: {passed} passed, {failed} failed, {skipped} skipped")
    logging.info("=" * 70)
    
    results["summary"] = {
        "passed": passed,
        "failed": failed,
        "skipped": skipped,
        "total": len(test_cases)
    }
    
    # Save results as JSON
    results_file = Path("test-results/distributed_test_results.json")
    with open(results_file, "w") as f:
        json.dump(results, f, indent=2, default=str)
    
    logging.info(f"Results saved to {results_file}")
    
    # Exit with appropriate code
    if failed > 0:
        logging.error("TESTS FAILED")
        return 1
    else:
        logging.info("TESTS PASSED")
        return 0

if __name__ == "__main__":
    sys.exit(main())
