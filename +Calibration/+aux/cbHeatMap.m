function heatMapIm = cbHeatMap(pts,values,res)

X = pts(:,1);
Y = pts(:,2);
[Xq, Yq] = meshgrid(1:res(2),1:res(1)); 

Vq = interp2(X,Y,values,Xq,Yq);
heatMapIm = reshape(Vq,res);


end