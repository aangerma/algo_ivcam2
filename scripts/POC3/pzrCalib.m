
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
params.angxSO = [];
params.angySO = [];
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
[pp,ff] = icosphere(6);
nH = params.pzr2los(1:3);
ppH=pp*rotateAroundVector(pp(1,:),nH);
nV = params.pzr2los(4:6);
ppV=pp*rotateAroundVector(pp(1,:),nV);
nV =nV/norm(nV );
nH =nH/norm(nH );
iV = find(sqrt(sum((ppV-nV).^2,2))<.5);
iH = find(sqrt(sum((ppH-nH).^2,2))<.5 & ppH(:,1)>0 & ppH(:,2)>0);
%%

eH=nan(length(iH),1);
imH=cell(length(iH),1);

eV=nan(length(iV),1);
imV=cell(length(iV),1);

tic
parfor i=1:length(iV)
    ind = iV(i);
    fprintf('V %5.2f\n',i/length(iV)*100);
     PV=[.5       0          .5  ppV(ind,:) ];
     [eV(i),imV{i}]=errFuncV(PV,v,dt,params);
end

parfor i=1:length(iH)
    ind = iH(i);
    fprintf('V %5.2f\n',i/length(iH)*100);
    PH=[ppH(ind,:) 1/8 1 -1/8];
    [eH(i),imH{i}]=errFuncH(PH,v,dt,params);
end
eeV=nan(size(pp,1),1);
eeH=nan(size(pp,1),1);
eeV(iV)=eV;
eeH(iH)=eH;
save dbg 
toc