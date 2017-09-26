-- test

require 'xlua'
require 'image'
local loader = require 'loader'


local opt = {}
opt.trainPath = '/home/nashory/data/sample/single'
opt.nthreads = 8
opt.batchSize = 10
opt.loadSize = 160
opt.sampleSize = 128
opt.rotate = 0
opt.crop = 'random'
opt.padding = false
opt.hflip = false
opt.keep_ratio = true
opt.whitenoise = 0
opt.brightness = 0

print(opt)


local myloader = loader.new(opt)


function test_loading_speed()
    timer = torch.Timer()
    for i = 1, 100 do
       local batch = myloader:getBatch('train')
      print(string.format('try: %d, batch size: (%dx%dx%dx%d)', i, batch:size(1), batch:size(2), batch:size(3), batch:size(4)))
       xlua.progress(i, 100)
    end
    print(string.format('Result: %.2f sec elapsed.', timer:time().real))
end

function test_crop()
    os.execute('rm -rf cache')
    for i = 1, 10 do
        local sample = myloader:getSample('train')
        os.execute(string.format('mkdir -p test/crop'))
        image.save(string.format('test/crop/%d.png', i), sample)
    end
end

function test_padding()
    os.execute('rm -rf cache')
    for i = 1, 10 do
        local sample = myloader:getSample('train')
        os.execute(string.format('mkdir -p test/padding'))
        image.save(string.format('test/padding/%d.png', i), sample)
    end
end

function test_hflip()
    os.execute('rm -rf cache')
    for i = 1, 10 do
        local sample = myloader:getSample('train')
        os.execute(string.format('mkdir -p test/hflip'))
        image.save(string.format('test/hflip/%d.png', i), sample)
    end
end

function test_rotate()
    os.execute('rm -rf cache')
    for i = 1, 10 do
        local sample = myloader:getSample('train')
        os.execute(string.format('mkdir -p test/rotate'))
        image.save(string.format('test/rotate/%d.png', i), sample)
   end 
end

function test_add_noise()
    os.execute('rm -rf cache')
    local sample = myloader:getSample('train')
    os.execute(string.format('mkdir -p test/noise'))
    image.save(string.format('test/noise/%f.png', opt.whitenoise), sample)
end

function test_brightness()
    os.execute('rm -rf cache')
    for i = 1, 10 do
        local sample = myloader:getSample('train')
        os.execute(string.format('mkdir -p test/brightness'))
        image.save(string.format('test/brightness/%d.png', i), sample)
    end
end

function test()
    -- loading speed test.
    --test_loading_speed()

    -- random crop test.
    test_crop()
    
    -- padding hflip test.
    --test_padding()

    -- hflip test
    --test_hflip()

    -- rotate test
   -- test_rotate()

    -- white noise test
    --test_add_noise()
    
    -- brightness test
    --test_brightness()

end


-- DO TEST.
test()



