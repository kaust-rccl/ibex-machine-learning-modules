#!/usr/bin/env python
"""
Comprehensive Distributed PyTorch Test Script
Tests various distributed patterns and communication primitives
"""

import os
import sys
import torch
import torch.distributed as dist
import torch.multiprocessing as mp
from torch.nn.parallel import DistributedDataParallel as DDP
import time

def setup(rank, world_size):
    """Initialize distributed process group"""
    os.environ['MASTER_ADDR'] = os.getenv('MASTER_ADDR', '127.0.0.1')
    os.environ['MASTER_PORT'] = os.getenv('MASTER_PORT', '12355')
    
    dist.init_process_group(
        backend='nccl',
        init_method='env://',
        rank=rank,
        world_size=world_size
    )
    torch.cuda.set_device(rank)

def cleanup():
    """Cleanup distributed process group"""
    dist.destroy_process_group()

def test_basic_communication(rank, world_size):
    """Test basic distributed communication primitives"""
    print(f"[Rank {rank}] Testing basic communication")
    
    # Test 1: All-reduce
    tensor = torch.ones(1).cuda(rank)
    dist.all_reduce(tensor, op=dist.ReduceOp.SUM)
    
    if rank == 0:
        expected = float(world_size)
        assert abs(tensor.item() - expected) < 0.01, f"All-reduce failed: {tensor.item()} != {expected}"
        print(f"[Rank {rank}] ✓ All-reduce test passed")
    
    # Test 2: Broadcast
    if rank == 0:
        tensor = torch.arange(10, dtype=torch.float32).cuda(rank)
    else:
        tensor = torch.zeros(10).cuda(rank)
    
    dist.broadcast(tensor, src=0)
    
    expected = torch.arange(10, dtype=torch.float32).cuda(rank)
    assert torch.allclose(tensor, expected), f"Broadcast failed on rank {rank}"
    if rank == 0:
        print(f"[Rank {rank}] ✓ Broadcast test passed")
    
    # Test 3: Gather
    tensor = torch.tensor([rank], dtype=torch.float32).cuda(rank)
    if rank == 0:
        gather_list = [torch.zeros(1).cuda(rank) for _ in range(world_size)]
        dist.gather(tensor, gather_list, dst=0)
        expected = torch.arange(world_size, dtype=torch.float32)
        result = torch.stack([t.cpu() for t in gather_list])
        assert torch.allclose(result, expected), f"Gather failed"
        print(f"[Rank {rank}] ✓ Gather test passed")
    else:
        dist.gather(tensor, dst=0)

def test_ddp_training(rank, world_size):
    """Test DistributedDataParallel training"""
    print(f"[Rank {rank}] Testing DDP training")
    
    # Simple model
    model = torch.nn.Sequential(
        torch.nn.Linear(20, 10),
        torch.nn.ReLU(),
        torch.nn.Linear(10, 1)
    ).cuda(rank)
    
    ddp_model = DDP(model, device_ids=[rank])
    
    # Loss and optimizer
    criterion = torch.nn.MSELoss()
    optimizer = torch.optim.SGD(ddp_model.parameters(), lr=0.01)
    
    # Training loop
    for epoch in range(5):
        # Generate fake data
        inputs = torch.randn(32, 20).cuda(rank)
        targets = torch.randn(32, 1).cuda(rank)
        
        # Forward pass
        outputs = ddp_model(inputs)
        loss = criterion(outputs, targets)
        
        # Backward pass
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        if rank == 0 and epoch % 2 == 0:
            print(f"[Rank {rank}] Epoch {epoch}, Loss: {loss.item():.4f}")
    
    if rank == 0:
        print(f"[Rank {rank}] ✓ DDP training test passed")

def test_all_gather(rank, world_size):
    """Test all-gather operation"""
    print(f"[Rank {rank}] Testing all-gather")
    
    # Each rank has unique data
    tensor = torch.tensor([rank * 10 + i for i in range(5)], dtype=torch.float32).cuda(rank)
    
    # All-gather
    gather_list = [torch.zeros(5).cuda(rank) for _ in range(world_size)]
    dist.all_gather(gather_list, tensor)
    
    # Verify
    for i, gathered in enumerate(gather_list):
        expected = torch.tensor([i * 10 + j for j in range(5)], dtype=torch.float32).cuda(rank)
        assert torch.allclose(gathered, expected), f"All-gather failed on rank {rank}"
    
    if rank == 0:
        print(f"[Rank {rank}] ✓ All-gather test passed")

def test_reduce_scatter(rank, world_size):
    """Test reduce-scatter operation"""
    print(f"[Rank {rank}] Testing reduce-scatter")
    
    # Input tensor list
    tensor_list = [torch.ones(5).cuda(rank) * (i + 1) for i in range(world_size)]
    output_tensor = torch.zeros(5).cuda(rank)
    
    # Reduce-scatter
    dist.reduce_scatter(output_tensor, tensor_list, op=dist.ReduceOp.SUM)
    
    # Verify
    expected = torch.ones(5).cuda(rank) * (rank + 1) * world_size
    assert torch.allclose(output_tensor, expected), f"Reduce-scatter failed on rank {rank}"
    
    if rank == 0:
        print(f"[Rank {rank}] ✓ Reduce-scatter test passed")

def run_tests(rank, world_size):
    """Run all distributed tests"""
    setup(rank, world_size)
    
    try:
        if rank == 0:
            print("=" * 60)
            print("Running Comprehensive Distributed Tests")
            print(f"World size: {world_size}")
            print("=" * 60)
        
        # Run tests
        test_basic_communication(rank, world_size)
        dist.barrier()
        
        test_all_gather(rank, world_size)
        dist.barrier()
        
        test_reduce_scatter(rank, world_size)
        dist.barrier()
        
        test_ddp_training(rank, world_size)
        dist.barrier()
        
        if rank == 0:
            print("=" * 60)
            print("✓ All distributed tests passed!")
            print("=" * 60)
            
    except Exception as e:
        print(f"[Rank {rank}] ✗ Test failed: {e}")
        raise
    finally:
        cleanup()

if __name__ == "__main__":
    world_size = torch.cuda.device_count()
    
    if world_size < 2:
        print(f"[ERROR] Need at least 2 GPUs, found {world_size}")
        sys.exit(1)
    
    print(f"Using {world_size} GPUs for distributed testing")
    mp.spawn(run_tests, args=(world_size,), nprocs=world_size, join=True)
