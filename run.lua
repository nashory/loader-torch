-- test


local loader = require 'loader'




local opt = {}
opt['batchSize'] = 96
opt['loadSize'] = 96
opt['sampleSize'] = 96
opt['trainPath'] = '/home/nashory/data/test'

print(opt)


local dataloader = loader.new(opt)






