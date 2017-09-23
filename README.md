# loader Package Reference Manual
Multi-threaded data loading module with image preprocessing for torch.  


## Core-functionality
+ Multi-threaded : blazingly fast data loading
+ Preprocessing : resizing / cropping / enhancing-contrast / rotating / normalizing / adjusting pixel range
+ Deatailed options : you can minutely control the output image condition.


## Benchmark: Single-thread vs. Multi-threads

__Test: total elapsed time of loading 10x3x64x64 batch for 100 times.__

|\# of threads|progress|result|
|---|---|---|
|1(single)|<img src="https://github.com/nashory/gif/blob/master/_loader/thread_1.gif" width="400">| 17.09 sec.|
|2(dual) | <img src="https://github.com/nashory/gif/blob/master/_loader/thread_2.gif" width="400">| 10.03 sec.|
|__8(octa)__ | <img src="https://github.com/nashory/gif/blob/master/_loader/thread_8.gif" width="400">| __8.51 sec.__|


## How to use?
1. Install the package:
~~~
luarocks install --server=http://luarocks.org/manifests/nashory loader
~~~

2. set loader options:  
You can pass data-loading options as format of lua table like below.
~~~
local opt = {}
opt['nthreads'] = 8
opt['batchSize'] = 40
opt['loadSize'] = 96
opt['sampleSize'] = 96
opt['trainPath'] = '/home/nashory/data/test'
~~~


3. create dataloader and get batch:
~~~
require 'loader'
local myloader = loader.new(opt)                 -- declaration
for i = 1, 100 do
    local batch = myloader:getSample('train')     -- get batch (batchSize x 3 x sampleSize x sampleSize)
end
~~~

## default options
if you do not specify the option, these values is applied by default.
default value "N/A" is for options you "must" specify. 

|option|default|help|
|---|---|---|
|nthreads|8|number or workers, (1 means single thread)|
|trainPath|'./data'|'path to train data folder.'|
|batchSize|N/A|image batchsize|
|loadSize|80|image is resized so the smallest length of w/h is equal to loadSize.|
|sampleSize|64|crop size. image is cropped so the w = h = sampleSize|
|split|1.0|split ratio (train/test)|
|crop|'random'|crop option for training. when testing, we force to use 'center' crop. (center \| random)|
|padding|false|true: add padding to make square image before resizing|
|keep_ratio|true|true: will keep the image ratio|


## code examples

~~~
will be updated soon.
~~~

## Acknowledgements
This code is referenced to the data loader of @soumith's [dcgan code](https://github.com/soumith/dcgan.torch)


## Author
MinchulShin, [@nashory](https://github.com/nashory)  
__Will keep updating the functionalities.__  
__Any insane bug reports or questions are welcome. (min.stellastra[at]gmail.com)  :-)__

