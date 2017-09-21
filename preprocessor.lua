-- preprocessing images.
-- todo:
-- shuffle
-- batch 
-- normalize
-- resize
-- padding
-- range
-- crop
-- rotation
-- contrast
-- gridconcat
-- lot of works to do ... sigh


require 'math'
require 'image'


local preprocessor = {}

function preprocessor.im_resize(im, imsize, keep_ratio)
    local iW = im:size(3)
    local iH = im:size(2)
    local out = nil
    if keep_ratio then
        if iW < iH then out = image.scale(im:clone(), imsize, imsize*iH/iW)
        else out = image.scale(im:clone(), imsize*iW/iH, imsize) end
    else
        out = image.scale(im:clone(), imsize, imsize)
    end
    return out
end


function preprocessor.im_crop(im, imsize, crop_option)
    assert(crop_option=='random', crop_option=='center')
    assert(im:size(3)>=imsize or im:size(2)>=imsize, 'error. image size is smaller than crop size.')
    local iW = im:size(3)
    local iH = im:size(2)
    local out = nil
    if crop_option == 'random' then
        local h1 = math.ceil(torch.uniform(1e-2, iH-imsize))
        local w1 = math.ceil(torch.uniform(1e-2, iW-imsize))
        out = image.crop(im, w1, h1, w1+imsize, h1+imsize)
    elseif crop_option == 'center' then
        out = image.crop(im, 'c', imsize, imsize)    
    end
    assert(out:size(2)==imsize and out:size(3)==imsize)
    collectgarbage()
    return out
end


function preprocessor.im_hflip(im)
    local p = torch.uniform()
    if p>0.5 then return image.hflip(im)
    else return im end
end

function preprocessor.adjust_range(im, range)
    assert(range=='[0,1]' or range=='[-1,1]',
    'pixel_range option should be "[0,1]" or "[-1,1]"')
    local out = im:clone()
    if range=='[-1,1]' then return out:mul(2):add(-1)
    else return out end
end

return preprocessor










