clear;
rng(10)
a=1;
str = sprintf('Had enough? send CV to:\ntom.aviram@intel.com');
imTXT=imresize(str2img(str),1,'nearest');
imTXT = padarray(imTXT,[10 4],'both');

[y,x]=ndgrid(linspace(-1,1,size(imTXT,1)),linspace(-1,1,size(imTXT,2)));
x=x+0.2;
y=y-0.7;

th=randn(6,1);
F=normByMax(reshape(generateLSH([x(:) y(:)],2)*th,size(x)));
% F=normByMax(0.3*x.^2+0.5*y.^2-2.3*x.*y);


F=uint8(F*(255-a));
 im= F+uint8(imTXT*a);

 str2 = sprintf('  CAN YOU\nSOLVE THIS?');
 imOL=str2img(str2)*255;
 imOL = uint8(padarray(imOL,(size(im)-size(imOL))/2,'both'));
%    im=im+imOL/2;
 imS=uint8(cat(3,im,im+imOL*0,im+imOL));
 
 imagesc(imS);axis image 
 
 imwrite(imS,'canyousolvethis.png')
 %%
 imR=double(imS(:,:,2))/255;
 xv=linspace(-1,1,size(imR,2));
 yv=linspace(-1,1,size(imR,1));
 [yg,xg]=ndgrid(yv,xv);
 
 genModel = @(X) generateLSH(X(:,1:2),2)\X(:,3);
 genErr = @(m,X) (generateLSH(X(:,1:2),2)*m-X(:,3));
 genErrL2 = @(m,X) (genErr (m,X)).^2;
  [~,th]=ransac([xg(:) yg(:) imR(:)],genModel,genErrL2,'errorThr',0.001,'iterations',3e3,'nModelPoints',7);
%   th = genModel([xg(:) yg(:) imR(:)]);
 subplot(211);
 imagesc(imR);axis image
 subplot(212);
 errImg = reshape(genErr(th,[xg(:) yg(:) imR(:)]),size(xg));
 imagesc(errImg*255);
 axis image