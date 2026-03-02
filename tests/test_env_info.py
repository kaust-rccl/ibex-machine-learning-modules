import subprocess
import torch

print("=== Environment Info ===")
print(f"Python: {subprocess.check_output(['python', '--version']).decode().strip()}")
print(f"PyTorch: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"GPU count: {torch.cuda.device_count()}")
print("")
subprocess.run(
    [
        "nvidia-smi",
        "--query-gpu=index,name,memory.total",
        "--format=csv",
    ],
    check=False,
)
print("")
