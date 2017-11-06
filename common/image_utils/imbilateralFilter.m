function o = imbilateralFilter(img,varargin)
%2D bilater filtering
% usage: imgfil = imbilateralFilter(img) filters img using default values
%        additional parameters (name value pairs):
%        size: kernel size (odd integer) default 3
%        sigS: spatial sigma default 0.5
%        sigR: radial sigma default input image std
%        cimg: cross img for radial data
%        weight: additional weighting image

    %input parsing
    p = inputParser;
    addRequired(p,'img',@isnumeric);
    addOptional(p,'size',3,@(x) mod(x,2)==1);
    addOptional(p,'sigS',0.5,@isnumeric);
    addOptional(p,'sigR',nanstd(img(:)),@isnumeric);
    addOptional(p,'weight',ones(size(img)),@(x) all(size(x)==size(img)));
    addOptional(p,'cimg',img,@(x) all(size(x)==size(img)));
     parse(p,img,varargin{:});
     arg = p.Results;
     clear p;
     
     %data to col
     k = (arg.size-1)/2;
     ind = im2col(reshape(1:numel(img),size(img)),[2 2]*k+1,'sliding');
     midInd = (k*2+1)*k+k+1;
     v=double(img(ind));
     v(isnan(v))=0;
     c = double(arg.cimg(ind));
     %build weight
     ws = fspecial('gaussian',[arg.size arg.size],arg.sigS);ws = ws(:);
     wr = exp(-0.5/arg.sigR^2*(bsxfun(@minus,c,c(midInd,:))).^2);
     wr = bsxfun(@rdivide,wr,nansum(wr));
     wr(isnan(wr))=0;
     wc = sum(arg.weight(ind));
     w = bsxfun(@times,bsxfun(@times,wr,ws),wc);
     sw = sum(w);
     sw(sw==0)=1;
     w=bsxfun(@rdivide,w,sw);
     %apply weights
     o = sum(w.*v);
     %reimage
     o = col2im(o,[2 2]*k+1,size(img));
     %padd borders
     o = padarray(o,[k k],'replicate','both');
end