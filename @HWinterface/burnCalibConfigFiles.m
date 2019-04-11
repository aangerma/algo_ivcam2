function [  ] = burnCalibConfigFiles( obj, directory,verbose,fileType )
%WRITECALIBCONFIGFILES writes the files matching filetype from the
% directory. fileType should b either :'ConfigData', 'ConfigInfo','CalibData', 'CalibInfo',

if ~exist('verbose','var')
    verbose = 1;
end
if ~exist('fileType','var')
    fileType = {'ConfigData'; 'ConfigInfo';'CalibData'; 'CalibInfo'};
end
if ischar(fileType)
    fileType = {fileType};
end
for i = 1:numel(fileType)
    fnames = dir(fullfile(directory,['*',fileType{i},'*']));
    for fn = 1:numel(fnames)
        burnCmd = ['Wr',fileType{i},' ','"',fullfile(directory,fnames(fn).name),'"'];
        try
            obj.cmd(burnCmd);
            if verbose
               disp(burnCmd); 
            end
        catch
            if verbose
               fprintf('Table %s doesn''t have a place in EPROM, skipping...\n',fullfile(directory,fnames(fn).name)); 
            end
        end  
        
    end
end

end

