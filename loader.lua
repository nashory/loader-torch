-- Multi-threading
-- referenced (https://github.com/soumith/dcgan.torch/blob/master/data)
-- Copyright (c) 2017, Minchul Shin [See LICENSE file for details]

require 'os'
local Threads = require 'threads'
Threads.serialization('threads.sharedserialize')

local data = {}

local result = {}
local unpack = unpack and unpack or table.unpack


-- option list
-- 'threads', 'batchSize', 'manualSeed'

function data.new(_params)
    _params = _params or {}
    local self = {}
    for k,v in pairs(data) do
        self[k] = v
    end

    -- get params or set default value.
    __TRAIN_DATA_ROOT__=_params.trainPath
    local nthreads = _params.nthreads or 1                  -- default thread num is 1.
    local manualSeed = _params.manualSeed or os.time()      -- random seed. 


    --local donkey_file = 'donkey.lua'
    if nthreads > 0 then
        self.threads = Threads( nthreads,
                                function() require 'torch' end,
                                function(thread_id)
                                    opt = _params
                                    local seed = (manualSeed and manualSeed or 0) + thread_id
                                    torch.manualSeed(seed)
                                    torch.setnumthreads(1)
                                    print(string.format('Starting donkey with id: %d, seed: %d',
                                          thread_id, seed))
                                    assert(opt, 'option parameters not given')
                                    --paths.dofile('dataloader.lua')
                                    require('dataloader')
                                    loader=DataLoader(opt)
                                    --path.dofile(donkey_file)            -- init donkey.
                                end
                               )
    end

    local nTrainSamples = 0
    local nTestSamples = 0
    self.threads:addjob(    function() return loader:size('train') end,
                            function(c) nTrainSamples = c end)
    self.threads:addjob(    function() return loader:size('test') end,
                            function(c) nTestSamples = c end)
    self.threads:synchronize()
    self._trainlen = nTrainSamples
    self._testlen = nTestSamples

    return self
end

function data._getFromThreads()
    assert(opt.batchSize, 'batchSize not found.')
    return loader:sample(opt.batchSize)
end

function data._pushResult(...)
    local res = {...}
    if res == nil then self.threads:synchronize() end
    table.insert(result, res)
end

function data:getBatch()
    ---queue another job
    self.threads:addjob(self._getFromThreads, self._pushResult)
    self.threads:dojob()
    local res = result[1]
    result[1] = nil
    if torch.type(res) == 'table' then return unpack(res) end
    return res
end


function data:getSample()
    print('get sample image for test.')
end


function data:size(target)
    if target == 'train' then return self._trainlen
    elseif target == 'test' then return self._testlen
    elseif target == 'all' or target == nil then return (self._trainlen + self._testlen) end
end



return data























