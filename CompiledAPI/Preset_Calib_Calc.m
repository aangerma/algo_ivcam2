function [minRangeScaleModRef, ModRefDec] = Preset_Calib_Calc(InputPath,LaserPoints,maxMod_dec,sz,calibParams)
% function [dfzRegs,results,calibPassed] = Preset_Calib_Calc(InputPath,LaserPoints,maxMod_dec,sz,calibParams)
% description: 
%
% inputs:
%   InputPath -  path for input images  dir stucture InputPath\PoseN N =1:5
%        note 
%           I image naming I_*_000n.bin
%   calibParams - calibparams strcture.
%   LaserPoints - 
%   maxMod_dec -
%   sz
%                                  
% output:
%   minRangeScaleModRef - 
%   ModRefDec           - 
%   
%
    global g_output_dir g_calib_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff; % g_regs g_luts;
    fprintff = g_fprintff;
    % setting default global value in case not initial in the init function;
    if isempty(g_debug_log_f)
        g_debug_log_f = 0;
    end
    if isempty(g_verbose)
        g_verbose = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_dummy_output_flag)
        g_dummy_output_flag = 0;
    end
    
    if isempty(g_calib_dir)
        g_dummy_output_flag = 0;
    end

    calib_dir = g_calib_dir;
    PresetFolder = calib_dir;
    
    func_name = dbstack;
    func_name = func_name(1).name;
    if(isempty(g_output_dir))
        output_dir = fullfile(tempdir, func_name,'temp');
    else
        output_dir = g_output_dir;
    end
    
    if(isempty(fprintff))
        fprintff = @(varargin) fprintf(varargin{:});
    end

    % save Input
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'InputPath','LaserPoints','maxMod_dec', 'sz','calibParams');
    end
    [minRangeScaleModRef, ModRefDec] = Preset_Calib_Calc_int(InputPath,LaserPoints,maxMod_dec,sz,calibParams,output_dir,PresetFolder);       

    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'minRangeScaleModRef','ModRefDec');
    end

end



function [minRangeScaleModRef, ModRefDec] = Preset_Calib_Calc_int(InputPath,LaserPoints,maxMod_dec,sz,calibParams,output_dir,PresetFolder)
width = sz(2);
height = sz(1);
Frames = GetMinRangeImages(InputPath,width,height);
runParams.outputFolder = output_dir; % need update

%% Detecting ROI on low laser image
[whiteCenter,blackCenter,ROI_Coffset]=detectROI(Frames(1).i,runParams);
%% analyzing white and black patch
Wmax=[]; Wmean=[];Bmin=[]; 
for i=1:length(Frames)
%      IRmat=reshape([Frames{i}.i],imsize(1),imsize(2),FramesNum);IR=mean(IRmat,3);
    IR=Frames(i).i;
    wpatch=IR(round(whiteCenter(2)-ROI_Coffset(2)):round(whiteCenter(2)+ROI_Coffset(2)),round(whiteCenter(1)-ROI_Coffset(1)):round(whiteCenter(1)+ROI_Coffset(1)));
    bpatch=IR(round(blackCenter(2)-ROI_Coffset(2)):round(blackCenter(2)+ROI_Coffset(2)),round(blackCenter(1)-ROI_Coffset(1)):round(blackCenter(1)+ROI_Coffset(1)));
    %     figure(); imagesc(IR); hold all;
    %     rectangle('position', [round(whiteCenter(1)-ROI_Coffset(1)),round(whiteCenter(2)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
    %     rectangle('position', [round(blackCenter(1)-ROI_Coffset(1)),round(blackCenter(2)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
    [Wmax(i),Wmean(i),~]= getIRvalues(wpatch);
    [~,~,Bmin(i)]= getIRvalues(bpatch);
    
end

DR=double(Wmax-Bmin);
diffDR=diff(DR);diffWmean=diff(Wmean);
p=polyfit(LaserPoints,DR,2);
LaserDelta = LaserPoints(2)-LaserPoints(1);
lp=[LaserPoints,LaserPoints(end)+LaserDelta:LaserDelta:2*LaserPoints(end)];
fittedline=p(1)*lp.^2+p(2)*lp+p(3);

ParbMaxX=-p(2)/(2*p(1));
if(maxMod_dec<ParbMaxX)
    ModRefDec=maxMod_dec;
else
    ModRefDec=round(ParbMaxX);
end
minRangeScaleModRef=ModRefDec/maxMod_dec;

%% prepare output script
shortRangePresetFn = fullfile(PresetFolder,'shortRangePreset.csv');
shortRangePreset=readtable(shortRangePresetFn);
modRefInd=find(strcmp(shortRangePreset.name,'modulation_ref_factor')); 
if (p(1)> 0)
    warning('MinRange preset calibration failed: first parabola coefficient is possitive\n');
    warning('min modRef already saturated'); 
    minRangeScaleModRef = 0;
    ModRefDec = 0;
end 
%assert(p(1)<0 ,'MinRange preset calibration failed: first parabola coefficient is possitive');     
shortRangePreset.value(modRefInd) = minRangeScaleModRef;
writetable(shortRangePreset,shortRangePresetFn);
%% debug    
if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    subplot(1,3,1);
    plot(LaserPoints,Wmax,LaserPoints,Wmean); title('IR values- white patch');xlabel('laser modulation [dec]'); legend('max', 'mean');grid minor;
    subplot(1,3,2);hold all;
    plot(lp,fittedline);plot(LaserPoints,DR); title('DR: Wmax-Bmin');xlabel('laser modulation [dec]');grid minor
    subplot(1,3,3);
    plot(LaserPoints,double(Wmax)-Wmean); title(' Wmax-Wmean white patch');xlabel('laser modulation [dec]');grid minor;
    subplot(1,3,2);scatter(ModRefDec,p(1)*ModRefDec.^2+p(2)*ModRefDec+p(3));
    Calibration.aux.saveFigureAsImage(ff,runParams,'SRpresetLaserCalib','PresetDir');

end

end

function [frames] = GetMinRangeImages(InputPath,width,height)
    d = dir(InputPath);
    isub = [d(:).isdir]; %# returns logical vector
    nameFolds = {d(isub).name}';
    nameFolds(ismember(nameFolds,{'.','..'})) = [];
    nameFolds = sort(nameFolds);
    for i = 1:numel(nameFolds)
        path = fullfile(InputPath,nameFolds{i});
        frames(i).i = Calibration.aux.GetFramesFromDir(path,width, height);
        frames(i).i = Calibration.aux.average_images(frames(i).i);
    end
    
    global g_output_dir g_save_input_flag; 
    if g_save_input_flag % save 
            fn = fullfile(g_output_dir,'mat_files' , 'MinRange_im.mat');
            save(fn,'frames');
    end
end


function [max,mean,min]= getIRvalues(im)
im=im(:);
mean = nanmean(im);
max=prctile(im,98);
min=prctile(im,1);
end

function [whiteCenter,blackCenter,ROI_Coffset]=detectROI(im,runParams)
% detect corners and centers
[pts,gridsize] = Validation.aux.findCheckerboard(im,[]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
ff = Calibration.aux.invisibleFigure;
imagesc(im); hold on;

x=pts(:,1); y=pts(:,2);X=reshape(x,gridsize); Y=reshape(y,gridsize);
patchNum=(gridsize(1)-1)*(gridsize(2)-1);

xcenter=(X(1:end-1,1:end-1)+X(1:end-1,2:end))./2;xcenter=xcenter(:);
ycenter=(Y(1:end-1,1:end-1)+Y(2:end,1:end-1))./2;ycenter=ycenter(:);
recsize=[mean(diff(mean(X,1))),mean(diff(mean(Y,2)))];

scatter(xcenter(:),ycenter(:),'+','MarkerEdgeColor','r','LineWidth',1.5);
%% extract white and black ROI
th=0.8; % ROI size
ROI_Coffset=th*recsize./2;
for j=1:patchNum
    patch=im(round(ycenter(j)-ROI_Coffset(2)):round(ycenter(j)+ROI_Coffset(2)),round(xcenter(j)-ROI_Coffset(1)):round(xcenter(j)+ROI_Coffset(1)));
    meanPatch(j)=mean(patch(:));
    rectangle('position', [round(xcenter(j)-ROI_Coffset(1)),round(ycenter(j)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
end
[~,whitePatchix]=max(meanPatch);
whiteCenter=[xcenter(whitePatchix),ycenter(whitePatchix)];
[p, l]=ind2sub([gridsize(1)-1,gridsize(2)-1],whitePatchix);
blackPatchix=sub2ind([gridsize(1)-1,gridsize(2)-1],p,l-1);
blackCenter=[xcenter(blackPatchix),ycenter(blackPatchix)];
scatter(whiteCenter(1),whiteCenter(2),'+','MarkerEdgeColor','w','LineWidth',1.5);
scatter(blackCenter(1),blackCenter(2),'+','MarkerEdgeColor','k','LineWidth',1.5);

Calibration.aux.saveFigureAsImage(ff,runParams,'ROIforSRpresetLaerCalib','PresetDir');

end