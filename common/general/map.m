function [ oimg ] = map( lut, img )

oimg = reshape(lut(img), size(img));

end

