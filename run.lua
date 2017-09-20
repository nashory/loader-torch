-- test


local loader = require 'loader'




local opt = {}
opt['nthreads'] = 8
opt['batchSize'] = 40
opt['loadSize'] = 96
opt['sampleSize'] = 96
opt['trainPath'] = '/home/nashory/data/test'


print(opt)


local myloader = loader.new(opt)

for i = 1, 100 do
    print(i)
    local batch = myloader:getSample('train')
end

