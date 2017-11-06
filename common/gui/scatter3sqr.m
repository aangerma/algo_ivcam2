function a = scatter3sqr(x,y,z,s,c,alp)
cubeV = [0 0 0;       0 0 1;        0 1 0;        0 1 1;        1 0 0;        1 0 1;        1 1 0;        1 1 1;]-.5;
cubeF = [1 5 7 3 ;3 7 8 4;4 8 6 2 ;1 2 6 5;5 6 8 7 ;1 3 4 2];
cl = colormap(jet(length(x)));
cl = cl(round(normByMax(c)*(length(c)-1)+1),:);
a=zeros(length(x),1);
for i=1:length(a)
    a(i)=patch(x(i)+s*reshape(cubeV(cubeF,1),[],4)',y(i)+s*reshape(cubeV(cubeF,2),[],4)',z(i)+s*reshape(cubeV(cubeF,3),[],4)',cl(i,:),'facealpha',alp);
end

end