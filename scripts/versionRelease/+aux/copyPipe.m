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

fid = fopen(fullfile(baseDst,'entrypoint.m'),'w');
fprintf(fid,'function varargout = entrypoint(varargin)\n');
fprintf(fid,'varargout{:} = %s(varargin{:});\n',pipeEntryFunction);
fprintf(fid,'end\n');
fclose(fid);

fid = fopen(fullfile(baseDst,'setPath.m'),'w');


fprintf(fid,'function  setPath()\n');
fprintf(fid,'newIncPath = [pathdef '';'' cd '';'' genpath(fullfile(cd,''AlgoCommon%cCommon'')) '';'' fullfile(cd,''ivcam20'')];\n',filesep);
fprintf(fid,'path(newIncPath);\n');
fprintf(fid,'end\n');
fclose(fid);

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