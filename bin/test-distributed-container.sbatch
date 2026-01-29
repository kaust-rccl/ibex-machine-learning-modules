#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=v100:2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=32G
#SBATCH --partition=debug
#SBATCH --job-name=test-distributed-container
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

# ==============================================================================
# Distributed ML Libraries Test - Singularity Container
# ==============================================================================
# Tests distributed computing frameworks in the ML module container:
# - PyTorch Distributed (DDP, torchrun)
# - Dask Distributed
# - Ray Distributed
# - NCCL multi-GPU communication
# ==============================================================================

set -euo pipefail

echo "=========================================="
echo "Distributed ML Libraries Test"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "Date: $(date)"
echo "GPUs: $SLURM_GPUS_ON_NODE"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo ""

# Load ML module
module purge
module load rl9-gpustack
module load machine_learning/2026.01

if [[ -z "${ML_CONTAINER_PATH:-}" ]]; then
    echo "[FAIL] ML_CONTAINER_PATH not set"
    exit 1
fi

CONTAINER_PATH="${ML_CONTAINER_PATH}"
echo "[OK] Container: ${CONTAINER_PATH}"
echo ""

# Create test results directory
TEST_DIR="/ibex/user/$USER/ibex-machine-learning-modules/test-results"
mkdir -p "${TEST_DIR}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEST_LOG="${TEST_DIR}/distributed-test-${TIMESTAMP}.log"

echo "Test log: ${TEST_LOG}"
echo ""

# Bind mounts
BIND_MOUNTS="--bind /ibex/user/$USER"
BIND_MOUNTS="${BIND_MOUNTS} --bind $(pwd):/workspace"

# Distributed environment variables
export MASTER_ADDR=127.0.0.1
export MASTER_PORT=12355
export NCCL_DEBUG=INFO
export OMP_NUM_THREADS=6

echo "=========================================="
echo "Starting Container Tests"
echo "=========================================="

singularity exec --nv ${BIND_MOUNTS} "${CONTAINER_PATH}" /bin/bash -lc "

# Activate conda environment
source /opt/conda/etc/profile.d/conda.sh
conda activate ml-module

echo '=== Environment Info ==='
echo 'Python: '\$(python --version)
echo 'PyTorch: '\$(python -c 'import torch; print(torch.__version__)')
echo 'CUDA available: '\$(python -c 'import torch; print(torch.cuda.is_available())')
echo 'GPU count: '\$(python -c 'import torch; print(torch.cuda.device_count())')
echo ''
nvidia-smi --query-gpu=index,name,memory.total --format=csv
echo ''

# ==============================================================================
# Test 1: PyTorch Multi-GPU Detection
# ==============================================================================
echo '=== Test 1: PyTorch Multi-GPU Detection ==='
python -c \"
import torch
import sys

gpu_count = torch.cuda.device_count()
print(f'Detected {gpu_count} GPUs')

if gpu_count < 2:
    print('[WARN] Expected 2 GPUs, only found', gpu_count)
    sys.exit(0)  # Don't fail, just warn

for i in range(gpu_count):
    props = torch.cuda.get_device_properties(i)
    print(f'GPU {i}: {props.name} ({props.total_memory / 1e9:.1f} GB)')
    
print('[PASS] Multi-GPU detection')
\"
echo ''

# ==============================================================================
# Test 2: PyTorch NCCL Backend
# ==============================================================================
echo '=== Test 2: PyTorch NCCL Backend ==='
python -c \"
import torch
import torch.distributed as dist

if torch.cuda.device_count() < 2:
    print('[SKIP] Need 2+ GPUs for NCCL test')
else:
    if dist.is_nccl_available():
        print('[PASS] NCCL backend available')
    else:
        print('[FAIL] NCCL backend not available')
\"
echo ''

# ==============================================================================
# Test 3: Simple Distributed PyTorch (if 2 GPUs)
# ==============================================================================
echo '=== Test 3: PyTorch Distributed Data Parallel ==='
cat > /tmp/test_ddp.py <<'DDPEOF'
import os
import torch
import torch.distributed as dist
import torch.multiprocessing as mp
from torch.nn.parallel import DistributedDataParallel as DDP

def setup(rank, world_size):
    os.environ['MASTER_ADDR'] = '127.0.0.1'
    os.environ['MASTER_PORT'] = '12355'
    dist.init_process_group('nccl', rank=rank, world_size=world_size)
    torch.cuda.set_device(rank)

def cleanup():
    dist.destroy_process_group()

def test_ddp(rank, world_size):
    setup(rank, world_size)
    
    model = torch.nn.Linear(10, 10).to(rank)
    ddp_model = DDP(model, device_ids=[rank])
    
    # Test forward pass
    input_tensor = torch.randn(20, 10).to(rank)
    output = ddp_model(input_tensor)
    
    # Test all_reduce
    tensor = torch.ones(1).to(rank)
    dist.all_reduce(tensor, op=dist.ReduceOp.SUM)
    
    if rank == 0:
        expected = float(world_size)
        if abs(tensor.item() - expected) < 0.01:
            print(f'[PASS] DDP all_reduce: {tensor.item()} == {expected}')
        else:
            print(f'[FAIL] DDP all_reduce: {tensor.item()} != {expected}')
    
    cleanup()

if __name__ == '__main__':
    world_size = torch.cuda.device_count()
    if world_size < 2:
        print('[SKIP] Need 2+ GPUs for DDP test')
    else:
        mp.spawn(test_ddp, args=(world_size,), nprocs=world_size, join=True)
DDPEOF

python /tmp/test_ddp.py
echo ''

# ==============================================================================
# Test 4: Dask Distributed with CUDA
# ==============================================================================
echo '=== Test 4: Dask Distributed with CUDA ==='
python -c \"
try:
    from dask_cuda import LocalCUDACluster
    from dask.distributed import Client
    import time
    import torch
    
    n_gpus = torch.cuda.device_count()
    print(f'Available GPUs: {n_gpus}')
    
    # Create CUDA cluster with GPUs
    cluster = LocalCUDACluster(n_workers=n_gpus, 
                              threads_per_worker=2,
                              silence_logs=False,
                              CUDA_VISIBLE_DEVICES='0,1')
    client = Client(cluster)
    
    print(f'Dask CUDA cluster: {len(client.scheduler_info()[\\\"workers\\\"])} workers')
    
    # Test simple GPU computation
    def square_gpu(x):
        import cupy as cp
        arr = cp.array([x])
        return float((arr ** 2).get()[0])
    
    futures = client.map(square_gpu, range(10))
    results = client.gather(futures)
    
    expected = [x**2 for x in range(10)]
    if results == expected:
        print('[PASS] Dask CUDA distributed computation')
    else:
        print('[FAIL] Dask CUDA computation incorrect')
    
    # Test cuDF if available
    try:
        import cudf
        import dask_cudf
        
        # Create sample dataframe
        ddf = dask_cudf.from_cudf(cudf.DataFrame({'x': range(100)}), npartitions=n_gpus)
        result = (ddf.x ** 2).sum().compute()
        expected_sum = sum(x**2 for x in range(100))
        
        if abs(result - expected_sum) < 0.01:
            print('[PASS] Dask cuDF computation')
        else:
            print('[FAIL] Dask cuDF computation incorrect')
    except Exception as e:
        print(f'[SKIP] Dask cuDF test: {e}')
    
    client.close()
    cluster.close()
    
except ImportError as e:
    print(f'[SKIP] Dask CUDA not available: {e}')
except Exception as e:
    print(f'[FAIL] Dask CUDA test error: {e}')
\"
echo ''

# ==============================================================================
# Test 5: Ray Distributed
# ==============================================================================
echo '=== Test 5: Ray Distributed ==='
python -c \"
try:
    import ray
    
    ray.init(num_cpus=4, num_gpus=torch.cuda.device_count() if 'torch' in dir() else 0)
    
    @ray.remote
    def remote_square(x):
        return x ** 2
    
    futures = [remote_square.remote(i) for i in range(10)]
    results = ray.get(futures)
    
    expected = [x**2 for x in range(10)]
    if results == expected:
        print('[PASS] Ray distributed computation')
    else:
        print('[FAIL] Ray computation incorrect')
    
    ray.shutdown()
    
except Exception as e:
    print(f'[FAIL] Ray test error: {e}')
\"
echo ''

# ==============================================================================
# Test 6: MPI4py (if available)
# ==============================================================================
echo '=== Test 6: MPI4py ==='
python -c \"
try:
    from mpi4py import MPI
    
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    print(f'[PASS] MPI4py available (rank {rank}/{size})')
    
except ImportError:
    print('[SKIP] MPI4py not available')
except Exception as e:
    print(f'[FAIL] MPI4py error: {e}')
\"
echo ''

# ==============================================================================
# Summary
# ==============================================================================
echo '=========================================='
echo 'Test Summary'
echo '=========================================='
echo 'All distributed tests completed'
echo 'Check output above for [PASS]/[FAIL]/[SKIP] status'
echo ''

" 2>&1 | tee "${TEST_LOG}"

echo ""
echo "=========================================="
echo "Test completed"
echo "Log saved to: ${TEST_LOG}"
echo "=========================================="
