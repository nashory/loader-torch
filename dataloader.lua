-- dataloader
-- todo
-- sampler
-- labeler

require 'torch'
require 'image'
require 'sys'
require 'xlua'
local ffi = require 'ffi'
local class = require('pl.class')
local dir = require('pl.dir')
local argcheck = require 'argcheck'
local prepro = require 'preprocessor'


-- input arguments check. if not exist, set as default value.
local initcheck = argcheck{
    pack = true,
    help = [[ argument check if they exist ]],
    
    {   name='loadSize',
        type='number',
        help='loadSize' },

    {   name='sampleSize',
        type='number',
        help='sampleSize' },
    
    {   name='batchSize',
        type='number',
        help='batchSize' },

    {   name='trainPath',
        type='string',
        help='trainPath' },
    
    {   name='split',
        type='number',
        help='split ratio (train/test)',
        default=1.0    },

    
    {   name='verbose',
        type='boolean',
        help='verbose',
        default=true    },

}


-- basic settings
torch.setdefaulttensortype('torch.FloatTensor')
torch.setnumthreads(1)


-- dataloader
local dataloader = torch.class('DataLoader')


function dataloader:__init(...)

    -- argcheck
    local args = initcheck(...)
    for k,v in pairs(args) do self[k] = v end          -- push args into self.

    --self.verbose = true
    --self.trainPath = trainPath
    



    if not paths.dirp(self.trainPath) then
        error(string.format('Did not find directory: %s', self.trainPath))
    end

    -- a cache file of the training metadata (if doesn't exist, will be created)
    local cache = "cache"
    local cache_prefix = self.trainPath:gsub('/', '_')
    os.execute('mkdir -p cache')
    local trainCache = paths.concat(cache, cache_prefix .. '_trainCache.t7')


    -- cache
    if paths.filep(trainCache) then 
        print('Loading train metadata from cache')
        info = torch.load(trainCache)
        --self.xx = info.sdf                -- restore variables.
    else
        print('Creating train metadata')
        self:create_cache()
    end 
end



function dataloader:size(target, class)
    assert( target=='train' or target=='test' or target=='all' or target==nil,
            'options : train | test | all')
    
    if target == 'train' then
        local list = self.classListTrain
        if not class then return self.numTrainSamples
        elseif type(class)=='string' then return list[self.classIndices[class]]:size(1)
        elseif type(class)=='number' then return list[class]:size(1) end
    elseif target == 'test' then
        local list = self.classListTest
        if not class then return self.numTestSamples
        elseif type(class)=='string' then return list[self.classIndices[class]]:size(1)
        elseif type(class)=='number' then return list[class]:size(1) end
    elseif target == 'all' or target==nil then
        local list = self.classList
        if not class then return self.numSamples
        elseif type(class)=='string' then return list[self.classIndices[class]]:size(1)
        elseif type(class)=='number' then return list[class]:size(1) end
    end
end


function dataloader:create_cache()
    self.classes = {}
    local classPaths = {}
    
    -- search and return key value of table element.
    local function tableFind(t,o) for k,v in pairs(t) do if v == o then return k end end end
    
    -- loop over each paths folder, get list of unique class names.
    -- also stor the directory paths per class
    for k, path in ipairs({self.trainPath}) do
        local dirs = dir.getdirectories(path)
        for k, dirpath in ipairs(dirs) do
            local class = paths.basename(dirpath)            -- set class name (folder basename)
            local idx = tableFind(self.classes, class)      -- find class idx
            if not idx then
                table.insert(self.classes, class)         -- insert class names
                idx = #self.classes                         -- indexing
                classPaths[idx] = {}                   
            end
            if not tableFind(classPaths[idx], dirpath) then
                table.insert(classPaths[idx], dirpath)      -- save path info for each class.
            end
        end
    end

    self.classIndices = {}
    for k, v in ipairs(self.classes) do self.classIndices[v] = k end    -- indexing w.r.t class name
    
    -- define command-line tools.
    local wc = 'wc'
    local cut = 'cut'
    local find = 'find -H'   -- if folder name is symlink, do find inside it after dereferencing
    if jit.os == 'OSX' then
        wc = 'gwc'
        cut = 'gcut'
        find = 'gfind'
    end

    -- Options for the GNU find command
    local extList = {'jpg','jpeg','png','JPG','PNG','JPEG','ppm','PPM','bmp','BMP'}
    local findOptions = ' -iname "*.' .. extList[1] .. '"'
    for i=2,#extList do findOptions = findOptions .. ' -o -iname "*.' .. extList[i] .. '"' end
    
    -- find the image path names
    self.imagePath = torch.CharTensor()
    self.imageClass = torch.LongTensor()
    self.classList = {}
    self.classListSample = self.classList

    print(   'running "find" on each class directory, and concatenate all'
          .. ' those filenames into a single file containing all image paths for a given class')

    -- so, generate one file per class
    local classFindFiles = {}
    for i=1, #self.classes do classFindFiles[i] = os.tmpname() end
    local combinedFindList = os.tmpname()       -- will combine all here.
    
    local tmpfile = os.tmpname()
    local tmphandle = assert(io.open(tmpfile, 'w'))
    -- iterate over classes
    for i, class in ipairs(self.classes) do
        -- iterate over classPaths
        for j, path in ipairs(classPaths[i]) do
            local command = find .. ' "' .. path .. '" ' .. findOptions
                            .. ' >>"' .. classFindFiles[i] .. '" \n'
            tmphandle:write(command)
        end
    end
    io.close(tmphandle)
    os.execute('bash ' .. tmpfile)
    os.execute('rm -f ' .. tmpfile)
    
    print('now combine all the files to a single large file')
    local tmpfile = os.tmpname()
    local tmphandle = assert(io.open(tmpfile, 'w'))
    -- cocat all finds to a single large file in the order of self.classes
    for i = 1, #self.classes do
        local command = 'cat "' .. classFindFiles[i] .. '" >>' .. combinedFindList .. ' \n'
        tmphandle:write(command)
    end
    io.close(tmphandle)
    os.execute('bash ' .. tmpfile)
    os.execute('rm -f ' .. tmpfile)


    -- now we have the large concatenated list of sampel paths. let's push it to self.imagPath!
    print('load the large concatenated list of sample paths to self.imagePath')
    local maxPathLength = tonumber(sys.fexecute(wc .. " -L '"
                                                   .. combinedFindList .. "' |"
                                                   .. cut .. " -f1 -d' '")) + 1
    local length = tonumber(sys.fexecute(wc .. " -l '"
                                            .. combinedFindList .. "' |"
                                            .. cut .. " -f1 -d' '"))
    assert(length > 0, "Could not find any image file in the give input paths")
    assert(maxPathLength > 0, "paths of files are length 0?")
    self.imagePath:resize(length, maxPathLength):fill(0)
    local s_data = self.imagePath:data()        -- return cdata char.
    local cnt = 0
    for line in io.lines(combinedFindList) do
        ffi.copy(s_data, line)                  -- ffi enables LuaJIT speed access to Tensors.
        s_data = s_data + maxPathLength
        if self.verbose and cnt%100 == 0 then
            xlua.progress(cnt,length)
        end
        cnt = cnt + 1
    end

    self.numSamples = self.imagePath:size(1)
    if self.verbose then print(self.numSamples .. ' samples found.') end
    
    -- now, we are going to update classList and imageClass.
    print('Updating classLIst and image Class appropriately')
    self.imageClass:resize(self.numSamples)
    local runningIndex = 0
    for i=1, #self.classes do
        if self.verbose then xlua.progress(i, #self.classes) end
        local length = tonumber(sys.fexecute(wc .. " -l '"
                                                .. classFindFiles[i] .. "' |"
                                                .. cut .. " -f1 -d' '"))
        if length == 0 then
            error('Class has zero samples')
        else
            self.classList[i] = torch.linspace(runningIndex + 1, runningIndex + length, length):long()
            self.imageClass[{{runningIndex+1, runningIndex+length}}]:fill(i)
        end
        runningIndex = runningIndex + length
    end

    -- clean up temp files.
    print('Cleaning up temporary files')
    local tmpfilelistall = ''
    for i=1,#classFindFiles do
        tmpfilelistall = tmpfilelistall .. ' "' .. classFindFiles[i] .. '"'
        if i % 1000 == 0 then
            os.execute('rm -f ' .. tmpfilelistall)
            tmpfilelistall = ''
        end
    end
    os.execute('rm -f '  .. tmpfilelistall)
    os.execute('rm -f "' .. combinedFindList .. '"')

    -- split train/test set.
    if self.split >= 1.0 then
        self.split = 1.0
        self.testIndicesSize = 0
    else
        print(string.format('Splitting training and tet sets to a ratio of %f(train) / %f(test)',
                self.split, 1.0-self.split))
        self.classListTrain = {}
        self.classListTest = {}
        self.classListSample = self.classListTrain
        local totalTestSamples = 0
        -- split the classList into classListTrain and classListTest
        for i=1,#self.classes do
            local list = self.classList[i]
            local count = self.classList[i]:size(1)
            local splitidx = math.floor(count*self.split + 0.5)     -- +round
            local perm = torch.randperm(count)                      -- mix (1 ~ count) randomly.
            self.classListTrain[i] = torch.LongTensor(splitidx)
            for j = 1, splitidx do                  -- (1 ~ splitidx) : trainset
                self.classListTrain[i][j] = list[perm[j]]
            end
            if splitidx == count then               -- all smaples were allocated to trainset
                self.classListTest[i] = torch.LongTensor()
            else 
                self.classListTest[i] = torch.LongTensor(count-splitidx)
                totalTestSamples = totalTestSamples + self.classListTest[i]:size(1)
                local idx = 1
                for j = splitidx+1, count do        -- (splitidx+1 ~ count) : testset
                    self.classListTest[i][idx] = list[perm[j]]
                    idx = idx + 1
                end
            end
        end
        -- Now combine classListTest into a single tensor
        self.testIndices = torch.LongTensor(totalTestSamples)
        
        self.numTestSamples = totalTestSamples
        self.numTrainSamples = self.numSamples - self.numTestSamples
        local tdata = self.testIndices:data()
        local tidx = 0
        for i=1,#self.classes do
            local list = self.classListTest[i]
            if list:dim() ~= 0 then
                local ldata = list:data()
                for j=0, list:size(1)-1 do
                    tdata[tidx] = ldata[j]
                    tidx = tidx + 1
                end
            end
        end
    end
end






















function dataloader:load_im(path)
    return image.load(path, nc, 'float')
end



function dataloader:trainHook(path)
    local im = self:load_im(path)
    -- resize image (always keeping ratio)
    --if opt.padding then input = prepro.resize(input, opt.loadSize, 'with_padding')
    --else input = prepro.resize(input, opt.loadSize, 'without_padding') end


    -- crop and hflip
    --local out = prepro.crop(input, opt.sampleSize, opt.crop)
    --if torch.uniform() > 0.5 then out = image.hflip(out) end
    
    -- adjust image value range.
    --if opt.pixrange == '[0,1]' then out = out
    --elseif opt.pixrange == '[-1,1]' then out:mul(2):add(-1) end
    return im
end




return dataloader








