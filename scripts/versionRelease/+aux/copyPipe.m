function baseSrc = copyPipe(baseDst)



pipeEntryFunction ='Pipe.autopipe';
pipeEntryFuncFn = which(pipeEntryFunction);
 depFuncs=aux.functionDependencyWalker(pipeEntryFuncFn,false);



baseSrc = fileparts(fileparts(fileparts(pipeEntryFuncFn)));

[~,lidarFldrName] = fileparts(fileparts(fileparts(cd)));


%add tables
depFuncs = [depFuncs;dirFiles(fullfile(baseSrc,lidarFldrName,'+Pipe',filesep,'tables'),'*.frmw')];
%add luts
depFuncs = [depFuncs;dirFiles(fullfile(baseSrc,lidarFldrName,'+Pipe',filesep,'LUTs'),'*.lut')];
%add specific
f = dirRecursive(fullfile(baseSrc,lidarFldrName),'compile_mex.m');
depFuncs = [depFuncs;f{1}];
depFuncs = [depFuncs;which('dirRecursive')];
f = dirRecursive(fullfile(baseSrc,lidarFldrName),'setpath*.m');
depFuncs = [depFuncs;f{1}];
f = dirRecursive(fullfile(baseSrc,lidarFldrName,'+Utils','src'));
depFuncs = [depFuncs;f];



%add H
cppHeadersSrc = dirRecursive(fileparts(pipeEntryFuncFn),'*.h');
depFuncs=[depFuncs;cppHeadersSrc];
for i=1:length(depFuncs)
    destfn =depFuncs{i};
    destfn = strrep(destfn,fullfile(baseSrc,lidarFldrName),fullfile(baseDst,'ivcam20'));
    destfn = strrep(destfn,baseSrc,baseDst);
    if(exist(destfn,'file'))
        fprintf('file exists, skipping (%s)\n',destfn);
        continue;
    end
    recmakedir(fileparts(destfn));  
    fprintf('%s -- > %s\n',depFuncs{i},destfn);
    copyfile(depFuncs{i},destfn)
end

fw = Firmware();

fw.writeDefs4asic([baseDst filesep  'ivcam20' filesep '+Pipe' filesep 'tables' filesep 'regsDefinitions.ASIC.csv']);

end


function recmakedir(bsdir)
if(isempty(bsdir) || exist(bsdir,'dir'))
    return;
end
recmakedir(fileparts(bsdir));
mkdir(bsdir);

end