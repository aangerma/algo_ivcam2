function img=letter2icon(c,resizeFact)
if(~exist('resizeFact','var'))
    resizeFact = 2;
end
img = str2img(c);
img = imresize(img,resizeFact,'nearest');
img = padarray(img,[1 1]);
img = min(img + circshift(circshift(img,1)',1)'*.5,1);
img = 1-img;
img(img==1)=nan;
img = cat(3,img,img,img);
end