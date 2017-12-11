
fldrs= dirFolders('\\invcam450\D\data\ivcam20\exp\20171129\','*',true);

[v,dt]=cellfun(@(x) folder2scopeData(x),fldrs,'uni',0);
dt=dt{1};
%%
params.irPreFilt = [3 166e6+[-30 30]*1e6];
params.irPostFilt = [3 0 64e6 ];
params.pzr2los = [  .5       0          .5       1/8 1 -1/8];
params.angxFilt = [3 0 15e3 ];
params.angyFilt = [3 0 50e3 ];
params.locPreFreq = 120e6;
params.locPostFreq = 10e6;
params.outFreq = 125e6;
params.locIRdelay = 114;
params.outBin = 1024;
params.angxSO = [12 0];
params.angySO = [2 0];
params.slowSO = [29e3 0];
%%
%H calib
[p1,p2]=ndgrid(linspace(0,2,40));p3=p1*0;
r=rotateAroundVector(cross([0;0;1],[1;1;1]/sqrt(3)),acos(1/sqrt(3)));
pp=r*[p1(:) p2(:) p3(:)]'+[0;0;1];
plot3(pp(1,:),pp(2,:),pp(3,:),'.',[1 0 0],[0 1 0],[0 0 1],'+');
hold on;quiver3([-1 0 0],[;0 -1 0],[;0 0 -1],[2 0 0],[0 2  0],[0 0 2],0,'k');hold off
view(60,22);
grid on
axis equal
%%
[pp,~] = icosphere(4);

%%
n = size(pp,1);
eH=nan(n,1);
imH=cell(n,1);

eV=nan(n,1);
imV=cell(n,1);

n=numel(eH);
for i=1:n
    disp(i/n);
    PV=[.5       0          .5  pp(i,:) ];
    [eV(i),imV{i}]=errFuncC(PV,v,dt,params);
    
    
    PH=[pp(i,:) 1/8 1 -1/8];
    if(PH(1)<0 || PH(3)<0)
        continue;
    end
    [eH(i),imH{i}]=errFuncC(PH,v,dt,params);
    
end



save dbg 
