function [fw,p] = loadFirmware(varargin)
p = inputHandler(varargin{:});

fw = Firmware();
fw.setRegHandle(p.regHandle);





if(~exist(p.modeFile,'file'))
    error('Could not find mode file (%s)',p.modeFile);
end
fw.setRegs(p.modeFile);

if(exist(p.configFile,'file'))
    fw.setRegs(p.configFile);
end


if(exist(p.calibFile,'file'))
    fw.setRegs(p.calibFile);
end
dnnWeightFile = fullfile(fileparts(p.calibFile),'dnnweights.csv');
innWeightFile = fullfile(fileparts(p.calibFile),'innweights.csv');
undistMdlFile = fullfile(fileparts(p.calibFile),'FRMWundistModel.bin32');
dcorFineTmpltFile = fullfile(fileparts(p.calibFile),'DCORtmpltFine.bin32');
dcorCrseTmpltFile = fullfile(fileparts(p.calibFile),'DCORtmpltCrse.bin32');


if(exist(dnnWeightFile,'file'))
    fw.setRegs(dnnWeightFile);
end

if(exist(innWeightFile,'file'))
    fw.setRegs(innWeightFile);
end

if(exist(undistMdlFile,'file'))
    fw.setLut(undistMdlFile);
end

if(exist(dcorFineTmpltFile,'file'))
    fw.setLut(dcorFineTmpltFile);
end
if(exist(dcorCrseTmpltFile,'file'))
    fw.setLut(dcorCrseTmpltFile);
end

if(p.rewrite)
    fw.writeUpdated(p.configFile);
    fw.writeUpdated(p.modeFile);
    fw.writeUpdated(p.calibFile);
end

%register overide
setRegs=struct();
if(p.debug~=-1)
    
    setRegs.MTLB.debug=p.debug==1;
end
if(p.fastApprox~=-1)
    setRegs.MTLB.fastApprox=dec2bin(uint8(p.fastApprox),8);
end
fw.setRegs(setRegs,[]);



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
if(exist(ivsFilename,'file')~=7)%check for file
    [basedir, subDir] = fileparts(ivsFilename);
elseif(exist(ivsFilename,'dir'))
    [basedir, subDir] = fileparts(fullfile(ivsFilename,filesep));
else
    error('Could not file file/folder %s',ivsFilename);
end
defs.outputDir = fullfile(basedir,filesep,subDir,filesep);
defs.calibfn = fullfile(basedir,filesep,'calib.csv');
defs.configfn =fullfile(basedir,filesep,'config.csv');
defs.modefn =fullfile(basedir,filesep,'mode.csv');

%% varargin parse
p = inputParser;

isfile = @(x) true;
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