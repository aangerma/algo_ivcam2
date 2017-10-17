function [ivs,referenceOffset,rgtImg,igtImg]=runSim2D(mdl,pSim1d,pSim2d)


%%
%reference offset calibration
N=30;
TGT =10;
CL = 20;
REF_TARGET_LOC = Utils.dtnsec2rmm(TGT);
pSim1dRO = pSim1d;

pSim1dRO.APD.darkCurrentAC=0;
pSim1dRO.APD.darkCurrentDC=0;
pSim1dRO.TIA.preAmpIRN=0;
pSim1dRO.environment.ambientNoise=0;
pSim1dRO.environment.ambientNoiseFactor=0;
pSim1dRO.TIA.inputBiasCurrent=0;
pSim1dRO.APD.excessNoiseFactor=0;
pSim1dRO.laser.txSequence = [1 zeros(1,CL-1) ];%delta;
pSim1dRO.runTime = CL*N;
pSim1dRO.Comparator.frequency=round(1/Utils.rmm2dtnsec(1));%
pSim1dRO.overSamplingRate=pSim1dRO.Comparator.frequency*10;
[chAro] = Simulator.runSim(struct('t',[0 50],'r',[1 1]*REF_TARGET_LOC,'a',[1 1]),pSim1dRO);
referenceOffset = reshape(chAro,length(pSim1dRO.laser.txSequence)*pSim1dRO.Comparator.frequency,N);

referenceOffset = referenceOffset(:,5:end);
referenceOffset = mean(referenceOffset,2);
referenceOffset = crossing([],referenceOffset,0.5);
referenceOffset = referenceOffset(1);
referenceOffset = referenceOffset/pSim1dRO.Comparator.frequency-TGT;

%%
CHUNK_TIME = 5000;

pSim1d.verbose=0;



ft = 1/pSim2d.fps*1e9;

pSim1d.runTime = CHUNK_TIME;
pSim1d.laser.txQuietHeadTime=0;


laserIncidentDirection = [0;0;-1];

switch(lower(pSim2d.slowAxisScanType))
    case 'linear'
        thetaX = @(t) pSim2d.mirAngx/2*(t/ft*2-1); %slow - linear
        pwrEnvX = @(t) ones(size(t));
    case 'sine'
        thetaX = @(t) -pSim2d.mirAngx/2*cos(t/ft*2*pi/2); %slow - sine
        %OSS 17/05/2016 17:27 commented pwrEnvX = @(t) abs(sin(t/ft*2*pi/2));
        %OSS 17/05/2016 17:28 begin
        % Changed the pwrEnv in case of sine to start at <lowerBound> and
        % cutoff at <upperBound>
        % Note that this is probably not a behaviour of a true modulator,
        % we would probably want something like
        % offSet+(upperbound-offset)*abs(sin(t/ft*2*pi/2))
        if (pSim2d.lowerBound > pSim2d.upperBound)
            error('pSim2d says: input argument <lowerBound> has to be greater than or equal to input argument <upperBound>')
        end
        pwrEnvX = @(t) max( (min( (abs(sin(t/ft*2*pi/2))), pSim2d.upperBound)), (pSim2d.lowerBound) )  ;
        %OSS 17/05/2016 17:28 end
    case 'tan'
        thetaX = @(t) atand(tand(pSim2d.mirAngx) * (2 * t/ft-1))/2;
        pwrEnvX = @(t) ones(size(t));
    otherwise
        error('unknonw slowAxisScanType');
end
thetaY = @(t) -pSim2d.mirAngy/2*cos(2*pi*t*pSim2d.fastMirrorFreq*1e-9); %fast
pwrEnvY = @(t) abs(sin(2*pi*t*pSim2d.fastMirrorFreq*1e-9));

if(pSim2d.applyPowerEnvolope)
    maxCurrent = pSim1d.laser.peakCurrent;
    pSim1d.laser.peakCurrent = @(t) pwrEnvX(t).*pwrEnvY(t)*maxCurrent;
    %OSS 18/05/2016 08:25 begin
    %verification purposes figure
    %figure ();
    %hold on;
    %xAxis=[0.1:0.001:1];
    %fX=pwrEnvX(xAxis);
    %plot(xAxis,fX);
    %hold off;
    %OSS 18/05/2016 08:25 end
end

t = linspace(0,ft,pSim2d.nRays)';

%{
[yg,xg]=ndgrid(linspace(-pSim2d.mirAngy/2,pSim2d.mirAngy/2,480),linspace(-pSim2d.mirAngx/2,pSim2d.mirAngx/2,640));
pg=griddata(thetaY(t),thetaX(t),pSim1d.laser.peakCurrent(t),yg,xg);
imagesc(pg);
%}

angles2xyz = @(angx,angy) [ sind(angx) cosd(angx).*sind(angy) cosd(angx).*cosd(angy)];
mirNormalXYZfunc = @(t) angles2xyz(thetaX(t),thetaY(t));


incidentOutXYZfunc_ = @(mirNormalXYZ) bsxfun(@plus,laserIncidentDirection',-bsxfun(@times,2*mirNormalXYZ*laserIncidentDirection,mirNormalXYZ));

incidentOutXYZfunc = @(t) incidentOutXYZfunc_(mirNormalXYZfunc(t));

incidentOutXYZ = incidentOutXYZfunc(t);

tblXYgen = @(ioXYZ) bsxfun(@times,[ioXYZ(:,1)./(ioXYZ(:,3)*tand(pSim2d.xFOVraster/2)),ioXYZ(:,2)./(ioXYZ(:,3)*tand(pSim2d.yFOVraster/2))]*.5+.5,[640 480]);%rasterize on plane

if(pSim2d.verbose)
    fprintf('Raytracing %d rays(%s)...',size(incidentOutXYZ,1),iff(useGPU(),'GPU','CPU'));
    
end
[r,a]=Simulator.aux.raytrace2d(mdl.faces,mdl.vertices,mdl.albedo,incidentOutXYZ,pSim2d.sensorOffset);
if(pSim2d.verbose)
    fprintf('Done\n')
end


if(pSim2d.verbose)
    %%
    figure(1);
    clf
    xyz = bsxfun(@times,incidentOutXYZ,1./sqrt(sum(incidentOutXYZ.^2,2)));
    xyz = bsxfun(@times,xyz,r);
    trisurf(mdl.faces,mdl.vertices(:,1),mdl.vertices(:,3),mdl.vertices(:,2));
    
    hold on;plot3(xyz(:,1),xyz(:,3),xyz(:,2),'.','markersize',1,'color','r');hold off;
    hold on;plot3(0,0,0,'k+',pSim2d.sensorOffset(1),pSim2d.sensorOffset(3),pSim2d.sensorOffset(2),'g+','markersize',20);hold off;
    xlabel('x');ylabel('z');zlabel('y')
    axis equal
    drawnow;
end
%%
% tTransient is the head time that should be trimmed from each chunk
tTransient = pSim1d.HPF.riseTime*2;
%% tStep is the step size, according to the total runtime and transient time
tStep=pSim1d.runTime-tTransient;
% step size should be a mutiplicant of all the frequencies
% (fast,slow,template). since the fast is in samples smaller than 1ns, we
% only need to take care of the the template and slow sampling rate, and
% the step should be the least common multiplican of them.
tStep =tStep - mod(tStep,lcm(1/pSim1d.HDRsampler.frequency,length(pSim1d.laser.txSequence)*pSim1d.laser.frequency));
%calculate new transient time
tTransient = pSim1d.runTime-tStep;
%data should start from these indices
nTransientA = tTransient*pSim1d.Comparator.frequency+1;
nTransientB = tTransient*pSim1d.HDRsampler.frequency+1;
assert(nTransientB==floor(nTransientB));
%%
nChunks = ceil(ft/tStep);

chAbuff={};
chBbuff={};
prprts={};

parfor i=1:nChunks
    pSim1d_I  = pSim1d;
    pSim1d_I.t0 = (i-1)*tStep;
    [chA_X,chB_X,prprts{i},~] = Simulator.runSim(struct('t',t,'r',r,'a',a),pSim1d_I);
    if(i==1)
        chAbuff{i}=chA_X';
        chBbuff{i}=chB_X';
    else
        chAbuff{i}=chA_X(nTransientA:end)';
        chBbuff{i}=chB_X(nTransientB:end)';
    end
    fprintf('[%5d/%5d]\n',i,nChunks);
end
% prprts=prprts{1};
chAbuff = [chAbuff{:}]';
chBbuff = [chBbuff{:}]';
%%

% % 

xyT = 64/pSim1d.Comparator.frequency;
% ioXYZ = incidentOutXYZfunc((0:xyT:ft)');
% tblXY = bsxfun(@times,[ioXYZ(:,1)./(ioXYZ(:,3)*tand(pSim2d.xFOVraster/2)),ioXYZ(:,2)./(ioXYZ(:,3)*tand(pSim2d.yFOVraster/2))]*.5+.5,[640 480]);%rasterize on plane
tblXY = tblXYgen(incidentOutXYZfunc((0:xyT:ft)'));



%create ground truth range image
xyr=[tblXYgen(incidentOutXYZfunc((t))) r];
xyr(isinf(r),:)=[];
[yg,xg]=ndgrid(1:480,1:640);
rgtImg=griddata(xyr(:,1),xyr(:,2),xyr(:,3),xg,yg);
%create ground truth intensity image
xya=[tblXYgen(incidentOutXYZfunc((t))) a];

igtImg=griddata(xya(:,1),xya(:,2),xya(:,3),xg,yg);
igtImg=0;igtImg./rgtImg.^2;


% save lidar2dDBG
ivs = struct();
ivs.xy = tblXY';
ivs.xy(1,:)=ivs.xy(1,:)*4;
ivs.xy = int16(ivs.xy);
ivs.slow = uint16(interp1((0:length(chBbuff)-1)/pSim1d.HDRsampler.frequency,double(chBbuff),(0:length(ivs.xy)-1)*xyT));
ivs.fast = chAbuff(1:size(ivs.xy,2)*64);
ivs.flags = uint8(zeros(1,size(ivs.xy,2)));
% ivs.properties=struct('fastF',pSim1d.Comparator.frequency,'slowT',xyT,'templateT',length(pSim1d.laser.txSequence),'xyT',xyT);





end

function o=useGPU()
o=true;
try
    gpuDevice(1);
catch
    o=false;
end
end
