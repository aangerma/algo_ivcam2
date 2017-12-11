function [pipeOutData] = autopipe(varargin)
%{
otions:
    viewResults
    saveTrace
    saveMAT
    verbose
    rewrite
    debug
    fastApprox
    saveResults
    memoryLayout
    regHandle
%}
%% input handle
p = inputHandler(varargin{:});


%%
if(isdir(p.ivsFilename))
    ivsFiles = dirFiles(p.ivsFilename,'*.ivs');
    memLayout = Pipe.setDefaultMemoryLayout();
    pipeOutData=[];
    for i=1:length(ivsFiles)
        if(p.verbose)
            fprintf('=======Batch %d/%d=======\n',i,length(ivsFiles));
        end
        pipeOutData = [pipeOutData Pipe.autopipe(ivsFiles{i},varargin{2:end},'memoryLayout',memLayout)];%#ok
        memLayout=pipeOutData(i).memoryLayoutOut;
    end
    if(p.saveResults)
        imwriteAnimatedGif({pipeOutData.iImg},[p.ivsFilename filesep 'buffer_ir.gif']);
        imwriteAnimatedGif({pipeOutData.zImg},[p.ivsFilename filesep 'buffer_depth.gif'],true);
    end
    return
end
    

%%
lgr = Logger(p.verbose,p.saveResults,fullfile(p.outputDir,'log.log'));
[~,fn] = fileparts(p.ivsFilename);

%% read .ivs
autoTic=tic;
lgr.print('Executing algo pipe\n');
lgr.print('-------------------\n');
lgr.print('Version:           %s\n', Pipe.version() );
lgr.print('Version location:  %s\n',fileparts(fileparts(which('Pipe.autopipe'))));
lgr.print('Input file:        %s\n',p.ivsFilename);
lgr.print('Host name:         %s\n',iff(isunix,getenv('HOST'),getenv('computername')));
lgr.print('User:              %s\n',iff(isunix,getenv('USER'),getenv('username')));
lgr.print('run started at:    %s\n',datestr(now,'YYYY mmm DD HH:MM:SS'));
%sRUNNING AUTOPIPE: %s\n',fn);
localTic=tic;
lgr.print('\tReading .ivs...');
if(~exist(p.ivsFilename,'file'))
    lgr.error('file %s does not exists',p.ivsFilename);
end
piStruct = io.readIVS(p.ivsFilename);
lgr.print(' done in %4.2f sec \n', toc(localTic));









%% CALIB & FIRMWARE
fwTic=tic; lgr.print('\tConfiguring Firmware...');

fw = Firmware();
fw.setRegHandle(p.regHandle);





if(~exist(p.modeFile,'file'))
    lgr.error('Could not find mode file (%s)',p.modeFile);
end
fw.setRegs(p.modeFile);

if(exist(p.configFile,'file'))
    fw.setRegs(p.configFile);
end


if(exist(p.calibFile,'file'))
    fw.setRegs(p.calibFile);
else
    %------------CALIBRATION BEGIN------------
    calibTic=tic; lgr.print('\n\t\tCalibrating...');
    Calibration.runcalibPipe(p.ivsFilename,'calibFile',p.calibFile,'modeFile',p.modeFile);
    lgr.print(' done in %4.2f sec \n', toc(calibTic));
    %------------CALIBRATION END------------
end
dnnWeightFile = fullfile(fileparts(p.calibFile),'dnnweights.csv');
innWeightFile = fullfile(fileparts(p.calibFile),'innweights.csv');
xlensMdlFile = fullfile(fileparts(p.calibFile),'FRMWxlensModel.bin32');
ylensMdlFile = fullfile(fileparts(p.calibFile),'FRMWylensModel.bin32');
if(exist(dnnWeightFile,'file'))
    fw.setRegs(dnnWeightFile);
end

if(exist(innWeightFile,'file'))
    fw.setRegs(innWeightFile);
end

if(exist(xlensMdlFile,'file'))
    fw.setLut(xlensMdlFile);
end
if(exist(ylensMdlFile,'file'))
    fw.setLut(ylensMdlFile);
end


if(p.rewrite)
    fw.writeUpdated(p.configFile);
    fw.writeUpdated(p.modeFile);
    fw.writeUpdated(p.calibFile);
end

%%% tmund write my own regs %%%
% perosnalRegs = getPersonalRegs();
% fw.setRegs(perosnalRegs,p.configFile);
% fw.writeUpdated(p.configFile);
% calibFilename = fullfile(p.outputDir,filesep,'calib.csv');
% fid=fopen(calibFilename,'w');
% fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[regs,luts] = fw.get();


%register overide
if(p.debug~=-1)
    regs.MTLB.debug=p.debug;
end
if(p.fastApprox~=-1)
    regs.MTLB.fastApprox=dec2bin(uint8(p.fastApprox),8);
end

memoryLayout = p.memoryLayout;

lgr.print2file('\n');
lgr.print2file(fw.disp()');

lgr.print(' done in %4.2f sec \n', toc(fwTic));

%% THE PIPE

%-----------------------------------PIPE BEGIN-----------------------------------%
[pipeOutData,pipeOutData.memoryLayoutOut] = Pipe.hwpipe(piStruct, regs, luts,memoryLayout,lgr,p.traceOutDir);
pipeOutData.regs = regs;
pipeOutData.luts = luts;
%-----------------------------------PIPE END  -----------------------------------%


%% save results
if(p.saveResults)
    fw.writeConfig4asic([p.outputDir 'RegsConfiguration.ASIC.csv']);
    Pipe.savePipeOutData(pipeOutData,p.outputDir,fn);
    
    if p.saveMAT
        outputMatFilename = [fullfile(p.outputDir,fn),'_results.mat'];
        save(outputMatFilename,'pipeOutData','regs','luts','-v7.3');
    end
    
    lgr.print('\tResults saved in : %s\n',p.outputDir);
end

%% view results
if(p.viewResults)
    img = Pipe.displayPipeOutData(pipeOutData,fn);
    if p.saveResults
        filetosave = fullfile(p.outputDir,sprintf('%s.%s',fn,'png'));
        imwrite(img,filetosave);
    end
end


lgr.print('Autopipe finished in %4.2f sec \n', toc(autoTic));
end












function p = inputHandler(ivsFilename,varargin)
%% defs
defs.viewResults = 1;
defs.saveTrace = 0;
defs.saveMAT = 0;
defs.verbose = 1;
defs.rewrite = 0;
defs.debug = -1;
defs.fastApprox = -1;
defs.saveResults = 1;
defs.memoryLayout = Pipe.setDefaultMemoryLayout();
defs.regHandle = 'throw';

if(~exist('ivsFilename','var'))
    ivsFilename = 'patgen::wall';
end

if(contains(ivsFilename,'::'))
    %special case, generate from patgen/regression
    %pattergenerator
    
    
    if(contains(ivsFilename,'patgen::'))
        patgenTxt = ivsFilename(9:end);
        ivsFilename = Pipe.patternGenerator(patgenTxt,'outputdir',tempdir);
        
        %regression
    elseif(contains(ivsFilename,'regression::'))
        if(ispc)
            regressionFolder = '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\Regression';
        else
            regressionFolder = '/nfs/iil/proj/perc/percsi_users2/eng/omenashe/Regression';
        end
        ivsFilename = strcat(regressionFolder,filesep,ivsFilename(13:end));
        if(~exist(ivsFilename,'dir'))
            error('Unknown regression file');
        end
        
        ivsFilename = dirFiles(ivsFilename,'*.ivs');
        ivsFilename = ivsFilename{1};
        defs.saveTrace = 0;
        defs.saveMAT = 0;
        defs.rewrite = 0;
        defs.saveResults = 0;
    else
        error('bad input');
        
        
        
    end
end
[basedir, subDir] = fileparts(ivsFilename);
defs.outputDir = fullfile(basedir,filesep,subDir,filesep);
defs.calibfn = fullfile(basedir,filesep,'calib.csv');
defs.configfn =fullfile(basedir,filesep,'config.csv');
defs.modefn =fullfile(basedir,filesep,'mode.csv');

%% varargin parse
p = inputParser;

isfile = @(x) exist(x,'file');
isflag = @(x) or(isnumeric(x),islogical(x));

addOptional(p,'outputDir',defs.outputDir);
addOptional(p,'saveResults',defs.saveResults,isflag);
addOptional(p,'saveTrace',defs.saveTrace,isflag);
addOptional(p,'saveMAT',defs.saveMAT,isflag);
addOptional(p,'verbose',defs.verbose,isflag);
addOptional(p,'debug',defs.debug,isflag);
addOptional(p,'viewResults',defs.viewResults,isflag);
addOptional(p,'calibFile',defs.calibfn,isfile);
addOptional(p,'configFile',defs.configfn,isfile);
addOptional(p,'modeFile',defs.modefn,isfile);
addOptional(p,'memoryLayout',defs.memoryLayout);
addOptional(p,'rewrite',defs.rewrite,isflag);
addOptional(p,'fastApprox',defs.fastApprox,@isnumeric);
addOptional(p,'regHandle','throw',@ischar);


parse(p,varargin{:});

p = p.Results;



p.ivsFilename = ivsFilename;
%remove " from filename;
p.ivsFilename(p.ivsFilename=='"')=[];
%create output dir(s)
if(p.saveTrace || p.saveMAT || p.saveResults)
    mkdirSafe(p.outputDir);
end
if(p.saveTrace)
    p.traceOutDir = fullfile(p.outputDir,filesep,'tracer',filesep);
    mkdirSafe(p.traceOutDir);
else
    p.traceOutDir =[];
end



end





