require 'nn'
require 'cunn'

local loadertest = torch.TestSuite()
local debug = false


function loadertest.testImageLoading()
    print('image loading test.')
end




function loader.test(tests, _debug)
    debug = _debug or false
    mytester = torch.Tester()
    mytester:add(loadertest)
    math.randomseed(os.time())
    mytester:run()
end

















