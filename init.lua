require 'nn'

loader = {}
loader.version = 1.0

unpack = unpack or table.unpack

torch.include('loader', 'test.lua')
torch.include('loader', 'preprocessor.lua')
torch.include('loader', 'loader.lua')

nn.loader = loader
