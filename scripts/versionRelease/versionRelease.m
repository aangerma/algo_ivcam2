function versionRelease(isOfficial)
if(~exist('isOfficial','var'))
    isOfficial = false;
end


rcBase = '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\GoldenPipeline\RC\';

%% Check that pipe is working on all regression DB
if(isOfficial)
    logfn=aux.runRegression(true);
else
    logfn='';
end


%% copy
verfileLoc = which('Pipe.version');

vertxt=regexp(fileread(verfileLoc ),'ver\s=\s''([^'']+)','tokens');
vertxt=vertxt{1}{1};
%change current pipe version

dstFolder = [datestr(now,'YYYY-mm-dd') '_' vertxt];
baseDst = fullfile(rcBase,dstFolder);
baseDstMatlab = fullfile(baseDst,'matlab');
baseSrc = aux.copyPipe(baseDstMatlab);
%check that the copied version runs
save2=cd;
cd(baseDstMatlab);
setPath;
entrypoint('patgen::debug','verbose',0,'viewResults',0,'savetrace',1);
cd(baseSrc);
setPath;
cd(fileparts(fileparts(verfileLoc)));
setPathFunc = dirFiles('.','setPath*.m');
run(setPathFunc{1})
cd(save2);
clear mex
if(exist('e','var'))
    error('Failed to run copied version %s',e.messege);
end


baseRef  = sort(dirRecursive(rcBase,'changelog.txt'));
baseRef = strcat(fileparts(baseRef{end}),filesep);




baseDstDoc = fullfile(baseDst,'doc\');
mkdir(baseDstDoc);
baseSrcDoc = '\\sharepoint.ger.ith.intel.com@SSL\DavWWWRoot\sites\3D_project\Shared Documents\Algo\IVCAM2.0\A.0%20ASIC%20Algo%20AD/';
docsfns = {'IVCAM2.0_DCOR_AD.docx'
    'IVCAM2.0_DEST_AD.docx'
    'IVCAM2.0_DIGG_AD.docx'
    'IVCAM2.0_RAST_AD.docx'
    'IVCAM2.0_STAT_AD.docx'
    'IVCAM2.0_JFIL_AD.docx'
    'IVCAM2.0_JFIL_BILAT_AD.docx'
    'IVCAM2.0_JFIL_EDGE_AD.docx'
    'IVCAM2.0_JFIL_FEXT_AD.docx'
    'IVCAM2.0_JFIL_NNET_AD.docx'
    'IVCAM2.0_JFIL_GEOM_AD.docx'
    'IVCAM2.0_JFIL_SORT_AD.docx'
    };
for i=1:length(docsfns)
    try
    copyfile(fullfile(baseSrcDoc,docsfns{i}),fullfile(baseDstDoc,docsfns{i}))
    catch
        warning('Failed to copy document %s',fullfile(baseSrcDoc,docsfns{i}));
    end
end
cmd=sprintf('xcopy  "%s" "\\\\Isamba.iil.intel.com\\nfs\\iil\\proj\\ivcam\\eng\\omenashe\\matlabReleases\\%s" /Y /D /E /C /R /K /I',baseDst,dstFolder);
system(cmd)

%% create changelog
chnglogfn=fullfile(baseDst,'changelog.txt');
if(~exist(chnglogfn,'file'))
    fid = fopen(chnglogfn,'w');
    fprintf(fid,'==========================================\n'										);
    fprintf(fid,'Golden Reference 2.0 A0 Release Notes\n'	  										);
    fprintf(fid,'Version: %s\n',vertxt					 	  										);
    fprintf(fid,'Date: %s\n',datestr(now,'mmm DD, YYYY') 	  										);
    fprintf(fid,'Executed by: %s@%s\n',getenv('username'),getenv('computername')					);
    fprintf(fid,'==========================================\n'										);
    fprintf(fid,'\n'																				);
    fprintf(fid,'TFS Repository path: Master branch($/IVCAM/Algo/LIDAR), IVCAM 2.0 V %s\n',vertxt	);
    fprintf(fid,'Description: A release of the current IVCAM 2.0 algorithms reference\n'		 	);
    fprintf(fid,'path: %s\n',baseDst															 	);
    fprintf(fid,'Regression DB changeset: %s\n',logfn											 	);
    fprintf(fid,'\n'																			 	);
    fprintf(fid,'Changelog:\n'																	 	);
    fprintf(fid,'------------------------------------------\n'										);
    fprintf(fid,'Added:\n'																			);
    fprintf(fid,'	-N/A\n'																			);
    fprintf(fid,'Changed:\n'																		);
    fprintf(fid,'	-N/A\n'																			);
    fprintf(fid,'Known issues:\n'																	);
    fprintf(fid,'	-N/A\n'																			);
    fclose(fid);
end

system(sprintf('start %s',chnglogfn))

visdiff(fullfile(baseRef,'matlab\'),fullfile(baseDst,'matlab\'));

end

