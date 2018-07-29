clear;
rng(10)
a=2;
str = sprintf('Had enough? send "7183" \n to perc_algo@intel.com');
imTXT=imresize(str2img(str),1,'nearest');
imTXT = padarray(imTXT,[10 4],'both');

[y,x]=ndgrid(linspace(-1,1,size(imTXT,1)),linspace(-1,1,size(imTXT,2)));



th=[1 9.2 size(imTXT,1)/size(imTXT,2) 0.1 -0.24 0]';
F=normByMax(reshape(generateLSH([x(:) y(:)],2)*th,size(x)));
% F=normByMax(0.3*x.^2+0.5*y.^2-2.3*x.*y);


F=round(F*(255-2*a)+a);
imTXTpm1=(imTXT.*((randi(2,size(imTXT,1),size(imTXT,2))-1)*2-1));
 im= round(F+(imTXTpm1*a));

 str2 = sprintf('  CAN YOU\nSOLVE THIS?');
 imOL=str2img(str2)*255;
 imOL = round(padarray(imOL,(size(im)-size(imOL))/2,'both'));
 
%    im=im+imOL/2;
awgn = @(s) round(randn(size(im))*s);
 imS=uint8(cat(3,im+awgn(0.00),im-imOL+awgn(6),im+imOL+awgn(6)));
 
 imagesc(im);axis image 
  imS=imresize(imS,5,'nearest');
  imS = imS+uint8(rand(size(imS))*2);
  
 imwrite(imS,'canyousolvethis.png')
 %%
 imR=double(imS(:,:,1))/255;
 imR=conv2(imR,ones(5)/25,'valid');
    imR=imR(1:5:end,1:5:end);
 xv=linspace(-1,1,size(imR,2));
 yv=linspace(-1,1,size(imR,1));
 [yg,xg]=ndgrid(yv,xv);
 
 genModel = @(X) generateLSH(X(:,1:2),2)\X(:,3);
 genErr = @(m,X) (generateLSH(X(:,1:2),2)*m-X(:,3));
 genErrL2 = @(m,X) (genErr (m,X)).^2;
%    [~,th]=ransac([xg(:) yg(:) imR(:)],genModel,genErrL2,'errorThr',0.001,'iterations',3e3,'nModelPoints',7);
    th = genModel([xg(:) yg(:) imR(:)]);
 subplot(211);
 imagesc(imR);axis image
 subplot(212);
 errImg = reshape(genErr(th,[xg(:) yg(:) imR(:)]),size(xg));
 imagesc(abs(errImg*255));
 axis image