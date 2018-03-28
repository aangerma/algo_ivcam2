function mdl=generateRandomSecene(seed)
rng(seed)
N_ELEMS=randi([10 100],1);
cubp=rand
vv=[];
ff=[];
cc=[];
S=randi([500 5000],1);
for i=1:N_ELEMS
    if(rand>.25)
        [v,f]=dataGen.Shapes.cube();
    else
        [v,f]=dataGen.Shapes.icosphere(1);
    end
    m=eye(4)+randn(4)*0.1;
    v = [v ones(size(v,1),1)]*m;
    v = v(:,1:3)./v(:,4);
    v = v*S/8;
    v = v+randn(1,3).*[.25 .25 .2]*S+[0 0 S];
    c = min(1,max(0,rand+0.1*randn(size(f,1),1)));
    [vv,ff,cc]=concatenateTriVert(vv,ff,cc,v,f,c);
end
mdl.v=vv;
mdl.f=ff;
mdl.a=cc;
end
