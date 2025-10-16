import logging
import torch
import torch.distributed as dist
import tensorflow as tf
from dask import delayed, compute
from dask.distributed import Client, LocalCluster

# Setup logging
log_file = "distributed_test.log"
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

logging.info("=== Distributed Computing Test ===")

def run_test(name, func):
    logging.info(f"--- {name} ---")
    try:
        func()
        logging.info(f"{name} passed. ✅")
    except Exception as e:
        logging.error(f"{name} failed. ❌ Error: {e}")

def test_dask():
    try:
        cluster = LocalCluster(n_workers=2, threads_per_worker=2)
        client = Client(cluster)
        @delayed
        def square(x):
            return x * x
        tasks = [square(i) for i in range(10)]
        results = compute(*tasks)
        logging.info(f"Dask results: {results}")
    finally:
        try:
            client.close()
            cluster.close()
        except Exception:
            pass

def test_pytorch_ddp():
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is not available for PyTorch DDP test.")
    # use a tcp init method and NCCL for GPUs; choose a free port if needed
    init_method = "tcp://127.0.0.1:12355"
    dist.init_process_group(backend="nccl", init_method=init_method, rank=0, world_size=1)
    try:
        device_id = torch.cuda.current_device()
        device = torch.device("cuda", device_id)
        model = torch.nn.Linear(10, 1).to(device)
        ddp_model = torch.nn.parallel.DistributedDataParallel(model, device_ids=[device_id], output_device=device_id)
        input_tensor = torch.randn(5, 10).to(device)
        output = ddp_model(input_tensor)
        logging.info(f"PyTorch DDP output: {output}")
    finally:
        dist.destroy_process_group()

def test_tensorflow_dist():
    # set memory growth to avoid TF grabbing all GPU memory
    try:
        gpus = tf.config.list_physical_devices('GPU')
        for g in gpus:
            try:
                tf.config.experimental.set_memory_growth(g, True)
            except Exception:
                pass
        strategy = tf.distribute.MirroredStrategy()
        with strategy.scope():
            model = tf.keras.Sequential([
                tf.keras.layers.Dense(10, activation='relu'),
                tf.keras.layers.Dense(1)
            ])
            model.compile(optimizer='adam', loss='mse')
            x = tf.random.normal((100, 5))
            y = tf.random.normal((100, 1))
            model.fit(x, y, epochs=1)
            logging.info("TensorFlow distributed training completed.")
    except Exception as e:
        logging.error(f"TensorFlow distributed failed: {e}")

run_test("Dask Distributed Test", test_dask)
run_test("PyTorch DDP Test", test_pytorch_ddp)
run_test("TensorFlow Distributed Strategy Test", test_tensorflow_dist)

logging.info("=== Distributed Test Completed. See 'distributed_test.log' for details. ===")
