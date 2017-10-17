function baseSrc = copyPipe(baseDst)



pipeEntryFunction ='Pipe.autopipe';
pipeEntryFuncFn = which(pipeEntryFunction);
 depFuncs=aux.functionDependencyWalker(pipeEntryFuncFn);



baseSrc = fileparts(fileparts(fileparts(pipeEntryFuncFn)));

lidarFldrName = regexp(cd,'\\Algo\\([^\\]+)','tokens');
lidarFldrName=lidarFldrName{1}{1};

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
    destfn = strrep(destfn,fullfile(baseSrc,lidarFldrName),fullfile(baseDst,'LIDAR'));
    destfn = strrep(destfn,baseSrc,baseDst);
    if(exist(destfn,'file'))
        fprintf('file exists, skipping (%s)\n',destfn);
        continue;
    end
    recmakedir(fileparts(destfn));  
    fprintf('%s -- > %s\n',depFuncs{i},destfn);
    copyfile(depFuncs{i},destfn)
end
% 
% 
% if(~isempty(cppHeadersSrc))
%     cppHeadersDst=strrep(cppHeadersSrc,fullfile(baseSrc,lidarFldrName),fullfile(baseDst,'LIDAR'));
%     if(~exist(fileparts(cppHeadersDst{1}),'dir'))
%     mkdir(fileparts(cppHeadersDst{1}));
%     end
%     for i=1:length(cppHeadersSrc)
%         fprintf('%s --> %s\n',cppHeadersSrc{i},cppHeadersDst{i});
%         
%         copyfile(cppHeadersSrc{i},cppHeadersDst{i})
%     end
% 
% end

fid = fopen(fullfile(baseDst,'entrypoint.m'),'w');
fprintf(fid,'function varargout = entrypoint(varargin)\n');
fprintf(fid,'varargout{:} = %s(varargin{:});\n',pipeEntryFunction);
fprintf(fid,'end\n');
fclose(fid);

fid = fopen(fullfile(baseDst,'setPath.m'),'w');


fprintf(fid,'function  setPath()\n');
fprintf(fid,'newIncPath = [pathdef '';'' cd '';'' genpath(fullfile(cd,''Common'')) '';'' fullfile(cd,''LIDAR'',[])];\n');
fprintf(fid,'path(newIncPath);\n');
fprintf(fid,'end\n');
fclose(fid);

fw = Firmware();

fw.writeDefs4asic([baseDst filesep  'LIDAR' filesep '+Pipe' filesep 'tables' filesep 'regsDefinitions.ASIC.csv']);

end


function recmakedir(bsdir)
if(isempty(bsdir) || exist(bsdir,'dir'))
    return;
end
recmakedir(fileparts(bsdir));
mkdir(bsdir);

end