function similarityCheck()

inputConfigFns = dirFiles('\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\RTLalign\','*.csv');

verAsp='\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\GoldenPipeline\RC\2017-05-14_0.9.9.C\matlab\setPath.m';
verBsp='\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\GoldenPipeline\RC\2017-05-17_0.9.9.D\matlab\setPath.m';


if(~exist(verAsp,'file'))
    error('File %s does not exists',verAsp);
end
if(~exist(verBsp,'file'))
    error('File %s does not exists',verBsp);
end

i=1;
ivsAfn = runPatgen(verAsp,inputConfigFns{i});
ivsBfn = runPatgen(verBsp,inputConfigFns{i});

compareIVS(ivsAfn,ivsBfn);

outA = runPipe(verAsp,ivsAfn);
outB = runPipe(verBsp,ivsAfn);

compareTrace(outA,outB);
return
releasesDir = '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\GoldenPipeline\RC';

runPipe('\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\GoldenPipeline\RC\2017-05-08_0.9.9.A\matlab\setPath.m')
%% find last release
d = dir(releasesDir);
d = {d.name};
d = d(3:end); %remove '.' '..'
dates = cellfun(@(x) str2double(x([1:4,6,7,9,10])),d);
lastReleaseName = d(maxind(dates));
lastReleaseName = lastReleaseName{1};

fprintf(['last release is "' lastReleaseName '"\n'])
%% compare ivs
fprintf('comparing old & new .ivs files...\n')

%run last release
run(fullfile(releasesDir,lastReleaseName,'matlab','setPath.m'));
ivsFnOld = getIvss(inputConfigFns,'oldPipeOldIvs');

% run new pipe
d = dir('..\..\setPath*');
run(fullfile('..','..',d.name));
ivsFnNew = getIvss(inputConfigFns,'newPipeNewIvs');

% compare ivs files
for  i=1:length(inputConfigFns)
    ivsDataOld = io.readIVS(ivsFnOld{i});
    ivsDataNew = io.readIVS(ivsFnNew{i});
    
    names = fieldnames(ivsDataOld);
    for j = 1:length(names)
        if(nnz(vec(ivsDataOld.(names{j}))-vec(ivsDataNew.(names{j})))>0)
            warning(['.ivs files dont match from last release ' lastReleaseName ' and current pipe: in field "' names{i} '" with config "' inputConfigFns{i} '"' ]);
        end
    end
end

%run new pipe with traces (with new ivs files)
for  i=1:length(inputConfigFns)
    Pipe.autopipe(ivsFnNew{i},'saveTrace',1,'verbose',0,'viewResults',0);
end

%run old pipe with traces (with new ivs files)
run(fullfile(releasesDir,lastReleaseName,'matlab','setPath.m'));
for  i=1:length(inputConfigFns)
    dirName = fullfile(tempdir,['oldPipeNewIvs' num2str(i)]);
    mkdirSafe(dirName);
    Pipe.autopipe(ivsFnNew{i},'saveTrace',1,'outputDir',dirName,'verbose',0,'viewResults',0);
end

%% compare traces
fprintf('comparing old & new traces (both pipes checked with new .ivs files)...\n')

diff = [];
for  i=1:length(inputConfigFns)
    d = dir(fullfile(tempdir,['oldPipeNewIvs' num2str(i)],'tracer'));
    d = {d.name};
    d = d(3:end);
    
    for j = 1:length(d)
        fileID = fopen(fullfile(tempdir,['oldPipeNewIvs' num2str(i)],'tracer',d{j}));
        A = fscanf(fileID,'%s');
        fclose(fileID);
        
        fileID = fopen(fullfile(fullfile(ivsFnNew{i}(1:end-4),'tracer',d{j})));
        B = fscanf(fileID,'%s');
        fclose(fileID);
        
        if(strcmp(A,B)~=1)
            diff{end+1} =  d{j};
            warning(['traces dont match from last release ' lastReleaseName ' and current pipe  with config "' inputConfigFns{i} '": ' d{j}]);
        end
    end
end

if(~isempty(diff))
    blockName = cellfun(@(x) x(length('tracer_')+1:length('tracer_')+4),diff,'UniformOutput',0);
    error(['traces dont match in blocks: ' strjoin(unique(blockName),', ')]);
end
fprintf('done!\n')


end

function ivsCell = getIvss(inputConfigs,instance)
ivsCell = cell(1,length(inputConfigs));
for i=1:length(inputConfigs)
    config = inputConfigs{i};
    dirName = fullfile(tempdir,[instance num2str(i)]);
    mkdirSafe(dirName);
    ivsCell{i} = Pipe.patternGenerator(config,'outputDir',dirName);
end
end
function ok = compareTrace(outA,outB)
visdiff(outA,outB);
ok=false;
end
function ok = compareIVS(ivsFnA,ivsFnB)
ok = true;
ivsDataB = io.readIVS(ivsFnB);
    ivsDataA = io.readIVS(ivsFnA);
    
    names = fieldnames(ivsDataB);
    for j = 1:length(names)
        if(nnz(vec(ivsDataB.(names{j}))-vec(ivsDataA.(names{j})))>0)
            warning('.ivs files dont match ');
            ok =false;
            return;
        end
    end
end

function ivsfn=runPatgen(setPathLoc,cfgfn)
s=path;
run(setPathLoc);
outDir = fullfile(tempdir,filesep,Pipe.version);
mkdirSafe(outDir);
try
ivsfn = Pipe.patternGenerator(cfgfn,'outputdir',outDir);
catch e,
    path(s);
    error(e.message);
end
path(s);
end

function [outDir,res]=runPipe(setPathLoc,ivsfn)
s=path;
run(setPathLoc);
outDir = fullfile(tempdir,filesep,Pipe.version);
mkdirSafe(outDir);
try
res = Pipe.autopipe(ivsfn,'savetrace',1,'viewResults',0,'outputdir',outDir);
catch e,
    path(s);
    disp(e.message);
end

end