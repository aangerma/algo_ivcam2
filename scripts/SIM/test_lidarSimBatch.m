clear;
modelFn = '\\invcam322\Ohad\data\models\random@1000.stl';
outDir = '\\invcam322\Ohad\data\lidar\SIM\random@1000\';
pSim1d = xml2structWrapper('\\invcam322\ohad\data\lidar\simulatorParams\params_860SKU1_indoor.xml');

ranges = [50 250 500 800 1000 1200 1500:250:4000];
txcode = Codes.propCode(32,1);


outDir = [outDir num2str(length(txcode)) '\'];
mkdir(outDir);


pSim1d.verbose=0;
pSim2d = struct('verbose',true,...
    'nRays',1e6,...
    'mirAngx',36,...
    'mirAngy',28,...
    'fastMirrorFreq',20e3,...
    'fps',60,...
    'laserIncidentDirection',[0;0;-1],...
    'sensorOffset', [30 0 0],...
    'slowAxisScanType','tan',...
    'xFOVraster',72,...
    'yFOVraster',56, ...
    'applyPowerEnvolope',true ...
    );

rng(1);


mdl = i_stlread(modelFn);
mdl.albedo = ones(size(mdl.faces,1),1)*.8;
mdl.vertices(:,3)=-mdl.vertices(:,3);
mdl.vertices(:,2)=mdl.vertices(:,2)-mean(minmax((mdl.vertices(:,2))));
mdl.vertices(:,1)=-(mdl.vertices(:,1)-mean(minmax((mdl.vertices(:,1)))));

for i=1:length(ranges)
    t = tic;
    mdlI = mdl;
    mdlI.vertices(:,3)=ranges(i)-mdlI.vertices(:,3);
    [ivs,referenceOffset,rgtImg,igtImg] = Simulator.runSim2D(mdl,pSim1d,pSim2d );
    ivlpifn = sprintf('%s%04d_run.ivlpi',outDir,ranges(i));
    io.writeIVLpi(ivlpifn,ivs);
    t = toc(t)
end
% 
% 
% io.writeBin(fullfile(basedir,[fn 'GT.binr']),rgtImg');
% io.writeBin(fullfile(basedir,[fn 'GT.bini']),igtImg');

rmConfigfn = [basedir '\Config.csv'];
rm = Firmware();
regs = rm.getRegs();
regs.MTLB.fastChDelayNsec=0;
regs.MTLB.slowChDelayNsec=0;
regs.DEST.txFRQpd00 = Utils.dtnsec2rmm(referenceOffset)*2;

rm.setRegs(regs);
rm.writeUpdated(rmConfigfn);
