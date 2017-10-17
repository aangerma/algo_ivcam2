W=300;
H=400;
M = 10;

cubeV = [0 0 0;       0 0 1;        0 1 0;        0 1 1;        1 0 0;        1 0 1;        1 1 0;        1 1 1;];
cubeF = [1 5 2;2 5 6;5 7 6;6 7 8;2 6 4;4 6 8;1 3 5;5 3 7;1 2 4;1 4 3;3 4 7;4 8 7];

v=[];
f=[];
vz=cubeV;
[v,f]=concatenateTriVert(v,f,vz,cubeF);

vz=bsxfun(@plus,bsxfun(@times,cubeV,[2 1 1]),[1 0 0]);
[v,f]=concatenateTriVert(v,f,vz,cubeF);

vz=bsxfun(@plus,bsxfun(@times,cubeV,[1 2 1]),[0 1 0]);
[v,f]=concatenateTriVert(v,f,vz,cubeF);

vz=bsxfun(@plus,bsxfun(@times,cubeV,[2 1.5 1]),[3 0 0]);
[v,f]=concatenateTriVert(v,f,vz,cubeF);

vz=bsxfun(@plus,bsxfun(@times,cubeV,[1.5 2 1]),[0 3 0]);
[v,f]=concatenateTriVert(v,f,vz,cubeF);


ew = max(v(:,1));
eh = max(v(:,2));
va=bsxfun(@plus,bsxfun(@times,cubeV,[W H M/2]),[0 0 0]);
fa=cubeF;
h = [0.5 1:100];
xymul=1;
while(true)
    j=1;
    while(true)
        vi = v;
        vi(:,1)=vi(:,1)*xymul + (j-1)*(ew*xymul+M)+M/2;
        vi(:,2)=vi(:,2)*xymul + eh*sum(1:(xymul-1))+M*(xymul-1)+M/2;
        vi(:,3)=vi(:,3)*h(j)+M/2;
        if(max(vi(:,1))>W)
            break;
        end
        if(max(vi(:,2))>H)
            break;
        end
        j=j+1;
        
        [va,fa]=concatenateTriVert(va,fa,vi,f);
        trisurf(fa,va(:,1),va(:,2),va(:,3));view(0,90);axis equal;
        
    end
    xymul=xymul+1;
    if(max(v(:,2)*xymul + eh*sum(1:(xymul-1))+M*(xymul-1))>H)
        break;
    end
end
%%
xylms = get(gca,{'xlim','ylim'});
set(gca,'xTick',0:5:W);
set(gca,'yTick',0:5:H);
stlwrite('Lchart.stl',fa,va)
