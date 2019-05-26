function [] = showEGeomPerIndicator(dataArr,ref)
figure;
for i = 1:numel(dataArr) % :11
data = dataArr(i);
tempData = [data.framesData.temp];

vBias = reshape([data.framesData.vBias],3,[]);
iBias = reshape([data.framesData.iBias],3,[]);
rBias = vBias./iBias;
eGeom = [data.framesData.eGeom];

subplot(531);
hold on,plot([tempData.ldd],eGeom),title('eGeom Over Ldd')
subplot(532);
hold on,plot([tempData.ma],eGeom),title('eGeom Over ma')
subplot(533);
hold on,plot([tempData.mc],eGeom),title('eGeom Over mc')
if isfield(tempData(1),'tSense')
    subplot(534);
    hold on,plot([tempData.tSense],eGeom),title('eGeom Over tSense')
    subplot(535);
    hold on,plot([tempData.vSense],eGeom),title('eGeom Over vSense')
end
subplot(536);
hold on,plot(vBias(1,:),eGeom),title('eGeom Over vBias 1')
subplot(537);
hold on,plot(vBias(2,:),eGeom),title('eGeom Over vBias 2')
subplot(538);
hold on,plot(vBias(3,:),eGeom),title('eGeom Over vBias 3')
subplot(539);
hold on,plot(iBias(1,:),eGeom),title('eGeom Over iBias 1')
subplot(5,3,10);
hold on,plot(iBias(2,:),eGeom),title('eGeom Over iBias 2')
subplot(5,3,11);
hold on,plot(iBias(3,:),eGeom),title('eGeom Over iBias 3')
subplot(5,3,12);
hold on,plot(rBias(1,:),eGeom),title('eGeom Over rBias 1')
subplot(5,3,13);
hold on,plot(rBias(2,:),eGeom),title('eGeom Over rBias 2')
subplot(5,3,14);
hold on,plot(rBias(3,:),eGeom),title('eGeom Over rBias 3')

if isfield(tempData(1),'apdTmptr')
    subplot(5,3,15);
    hold on,plot([tempData.apdTmptr],eGeom),title('eGeom Over Apd')
end
% figure(1907810);
% hold on; plot(vBias(1,:),vBias(3,:));
% xlabel('vBias1'); ylabel('vBias3');
end

subplot(5,3,1);hold on;
plot([ref.Ldd,ref.Ldd],[0,6]);
subplot(5,3,2);hold on;
plot([ref.ma,ref.ma],[0,6]);
subplot(5,3,3);hold on;
plot([ref.mc,ref.mc],[0,6]);
subplot(5,3,4);hold on;
plot([ref.tsense,ref.tsense],[0,6]);
subplot(5,3,5);hold on;
plot([ref.vsense,ref.vsense],[0,6]);


subplot(5,3,6);hold on;
plot([ref.vBias(1),ref.vBias(1)],[0,6]);
subplot(5,3,7);hold on;
plot([ref.vBias(2),ref.vBias(2)],[0,6]);
subplot(5,3,8);hold on;
plot([ref.vBias(3),ref.vBias(3)],[0,6]);

subplot(5,3,9);hold on;
plot([ref.iBias(1),ref.iBias(1)],[0,6]);
subplot(5,3,10);hold on;
plot([ref.iBias(2),ref.iBias(2)],[0,6]);
subplot(5,3,11);hold on;
plot([ref.iBias(3),ref.iBias(3)],[0,6]);

subplot(5,3,12);hold on;
plot([ref.rBias(1),ref.rBias(1)],[0,6]);
subplot(5,3,13);hold on;
plot([ref.rBias(2),ref.rBias(2)],[0,6]);
subplot(5,3,14);hold on;
plot([ref.rBias(3),ref.rBias(3)],[0,6]);
subplot(5,3,15);hold on;
plot([ref.apdTmptr,ref.apdTmptr],[0,6]);
end

