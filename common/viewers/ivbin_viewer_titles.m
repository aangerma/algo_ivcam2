function ivbin_viewer_titles(imgCell,titles)
% ivbin_viewer - A 3D renderer of depth images
if ~iscell(imgCell)
    imgCell = {imgCell};
end
if ~exist('titles','var')
%     fprintf('First calling variable is "%s"\n.', inputname(1))
    cellTitles = str2cell(num2str([1:length(imgCell)]));
    titles = cellTitles(1:2:end);
end
[path_str,~,ext_str] = fileparts(which('ivbin_viewer.m')); %#ok<NASGU>
viewer = fullfile(path_str,'IVBinViewerCS.exe');
if ~exist(viewer,'file')
    error('IVBinViewerCS.exe does not exist');
end
tempFolder = fileparts(tempname);

if (nargin == 0)
    % Simply launch the viewer without any data:
    system([viewer '&']);
else
    try
        for i=1:length(imgCell)
            if ~isequal(size(imgCell{i}),[480 640])
                imgCell{i} = imresize(imgCell{i},[480 640],'nearest');
%                 imgCell{i} = imresize(imgCell{i},[480 640],'bicubic');
            end
            tmpFileName = [tempFolder '\' titles{i} '_' char(rand(1,1)*5+50) char(rand(1,1)*5+50) '.bin'];
            [ivFileNames{i}] = au.formats.saveBinFile(tmpFileName,imgCell{i});
        end
    catch err
        rethrow(err);
    end
end

system([viewer ' ' strjoin(ivFileNames,' ') ' &']);


% DO NOT DELETE THE TEMP FILE!!!
% An async call is used for the viewer, meaning that the file may be
% deleted before it is read.
%delete(tmpFileName);
end
