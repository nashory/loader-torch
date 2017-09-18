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



require 'image'
local argcheck = require 'argcheck'




local preprocessor = torch.class('Preprocessor')



local initcheck = argcheck{
    pack=true,           -- return table contatining all arguments.
    help=[[ preprocessor ]],

    {   name='loadSize',
        type='number',
        help='loadSize'   },

    {   name='sampleSize',
        type='number',
        help='sampleSize'   },

    {   name='with_padding',
        type='boolean',
        default=true,
        help='sampleSize'   },

    {   name='with_hfilp',
        type='boolean',
        default=false,
        help='horizontal flip'   },

    {   name='with_padding',
        type='boolean',
        default=true,
        help='sampleSize'   },

    {   name='with_cropping',
        type='string',
        default='random',
        help='random | center | no'   },
}


function preprocessor:resize(im, size)
    local out = im
    return out
end

















