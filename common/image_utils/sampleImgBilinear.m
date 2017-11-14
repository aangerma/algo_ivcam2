function v = sampleImgBilinear(img,x,y)
y = max(min(y,size(img,1)),1);
x = max(min(x,size(img,2)),1);
y1 = floor(y);
x1 = floor(x);
y2 = y1+1;
x2 = x1+1;
v = img(y1,x1)*(x2-x )*(y2-y )+...
    img(y2,x1)*(x -x1)*(y2-y )+...
    img(y1,x2)*(x2-x )*(y -y1)+...
    img(y2,x2)*(x -x1)*(y -y1);

end
