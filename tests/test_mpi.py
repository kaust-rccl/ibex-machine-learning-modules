print("=== Test 6: MPI4py ===")

try:
    from mpi4py import MPI

    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()

    print(f"[PASS] MPI4py available (rank {rank}/{size})")
except ImportError:
    print("[SKIP] MPI4py not available")
except Exception as e:
    print(f"[FAIL] MPI4py error: {e}")
