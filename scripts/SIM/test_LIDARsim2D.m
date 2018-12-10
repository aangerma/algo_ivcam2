% clear;
modelFn = '\\invcam322\Ohad\data\lidar\SIM\sticks\random_sticks.stl';
outDir = '\\invcam322\Ohad\data\lidar\SIM\sticks\run2\';
mkdir(outDir);
mdl = i_stlread(modelFn);
mdl.albedo = ones(size(mdl.faces,1),1)*.8;
% mdl.vertices(:,3)=500-mdl.vertices(:,3);
%  mdl.vertices(:,2)=mdl.vertices(:,2)-mean(minmax((mdl.vertices(:,2))));
%  mdl.vertices(:,1)=-(mdl.vertices(:,1)-mean(minmax((mdl.vertices(:,1)))));
% mdl.vertices(:,1) = -mdl.vertices(:,1);

mdl.vertices = mdl.vertices*4;
 mdl.vertices(:,2) =mdl.vertices(:,2)-mean(minmax((mdl.vertices(:,2))));
 mdl.vertices(:,1)=(mdl.vertices(:,1)-mean(minmax((mdl.vertices(:,1)))));
r0 = rotation_matrix(pi/2,0,0);
r1 = rotation_matrix(0*pi/180,0,0);
mdl.vertices = mdl.vertices*r0*r1;
mdl.faces=mdl.faces(:,[1 3 2]);
mdl.vertices(:,3)=3000+mdl.vertices(:,3);
stlwrite(fullfile(outDir,'source.stl'),mdl);
%

pSim1d = xml2structWrapper('\\invcam270\ohad\data\lidar\simulatorParams\params_860SKU1_indoor.xml');
pSim1d.verbose=0;
pSim1d.laser.txSequence = Codes.propCode(64,1);
pSim2d = struct('verbose',true,...
    'nRays',1e4,...
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
%run sim


noisless = false;
if(noisless)
    pSim1d.APD.darkCurrentAC=0;
    pSim1d.APD.darkCurrentDC=0;
    pSim1d.APD.excessNoiseFactor=0;
    pSim1d.Comparator.irn=0;
    pSim1d.Comparator.jitterMaxC2C=0;
    pSim1d.Comparator.jitterRMS=0;
    pSim1d.Comparator.sensitivity=0;
    pSim1d.environment.ambientNoise=0;
    pSim1d.environment.ambientNoiseFactor=0;
    pSim1d.TIA.inputBiasCurrent=0;
    pSim1d.TIA.preAmpIRN=0;
end

trisurf(mdl.faces,mdl.vertices(:,1),mdl.vertices(:,3),mdl.vertices(:,2)); axis equal;axis vis3d
hold on
% plot3(0,0,0,'r+')
    [n,v]=calcNorms(mdl.vertices,mdl.faces);
    quiver3(v(:,1),v(:,3),v(:,2),n(:,1),n(:,3),n(:,2),5,'color','r');
    plotCam([1/tand(pSim2d.mirAngx) 0 0; 0 1/tand(pSim2d.mirAngy) 0 ; 0 0 1]*rotation_matrix(pi/2,0,pi),[0;0;0],150,[0 0 1])
    hold off;
    drawnow;
    zlabel('z');
     set(gca,'zdir','reverse')
    
     %%

fn = 'simrun';
t = tic;
[ivs,referenceOffset,rgtImg,igtImg] = Simulator.runSim2D(mdl,pSim1d,pSim2d );
t = toc(t);
io.writeIVS(fullfile(outDir,[fn '.ivs']),ivs);


io.writeBin(fullfile(outDir,[fn 'GT.binr']),rgtImg');
io.writeBin(fullfile(outDir,[fn 'GT.bini']),igtImg');
%%
configfn = [outDir '\Config.csv'];
calibfn = [outDir '\calib.csv'];
rm = Firmware();
regs = rm.getRegs();
cfgregs.GNRL.txCode = pSim1d.laser.txSequence==1;
cfgregs.GNRL.tx = pSim1d.laser.frequency;
cfgregs.GNRL.sampleRate = pSim1d.Comparator.frequency/pSim1d.laser.frequency;
cfgregs.GNRL.codeLength = length(pSim1d.laser.txSequence);
clbregs.MTLB.fastChDelayNsec=0;
clbregs.MTLB.slowChDelayNsec=0;
clbregs.DEST.txFRQpd00 = Utils.dtnsec2rmm(referenceOffset)*2;
clbregs.FRMW.xfov = pSim2d.xFOVraster;
clbregs.FRMW.yfov = pSim2d.yFOVraster;
clbregs.FRMW.xoffset=0;
clbregs.FRMW.yoffset=0;

rm.setRegs(cfgregs,configfn);
rm.writeUpdated(configfn);

rm.setRegs(clbregs,calibfn);
rm.writeUpdated(calibfn);


fprintf('Simulation runtime: %d minutes\n',round(t/60))
%%

% 
% calibData = xml2structWrapper(fullfile(fileparts(ivlpifn),'calibdata.xml'));
% pReconstruct = xml2structWrapper(fullfile(fileparts(ivlpifn),'pipeParams.xml'));
% pInput = io.readIVLpi(ivlpifn);
% [ pipeOutData ] = Pipe.hwpipe(pInput,pReconstruct,calibData );
% 
% Pipe.savePipeOutData(pipeOutData,calibData,ivlpifn);
% 
% 
% 
% pipeOut = Pipe.autopipe(ivlpifn);
