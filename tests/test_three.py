import torch
import torch.nn as nn
#check if cuda is available
print("Is CUDA available: ", torch.cuda.is_available())
#check if cuda is enabled
print("Is CUDA enabled: ", torch.cuda.is_built_with_cuda())
#check pytorch version
print("Pytorch version: ", torch.__version__)
#check tensor operation on GPU
a = torch.tensor([1, 2, 3, 4, 5, 6, 7], dtype=torch.float32)
b = torch.tensor([1, 2, 3, 4, 5, 6, 7], dtype=torch.float32)
c = torch.matmul(a, b)
# if this fails then you have a problem with your GPU
print("Pytorch operation on GPU: ", c)


