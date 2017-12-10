function ivbin_viewer(varargin)
    % ivbin_viewer - A 3D renderer of depth images
    %   Usage:  ivbin_viewer([param],[param2])
    %           ivbin_viewer([file,[var,[sq]]],[file,[var,[sq]]])
    %           ivbin_viewer([param],[file,[var,[sq]]])
    %           ivbin_viewer([file,[var,[sq]]],[param])
    %
    %       param:  cell-array or 2D/3D matrix
    %       mat:    Relative path and filename of a mat or bin file
    %       var:    A variable stored in the mat file
    %       sq:     Frame number in case of a sequence
    %
    % Locating the IVBinViewer application:
    [path_str,~,ext_str] = fileparts(which('ivbin_viewer.m')); %#ok<NASGU>
    viewer = fullfile(path_str,'IVBinViewerCS.exe');
    if ~exist(viewer,'file')
        error('IVBinViewerCS.exe does not exist');
    end
    
    % If input is weird cell - convert to noraml
    %     if iscell(varargin{1})
    %         varargin = cellfun(@(x) x{1},varargin,'uni',0);
    %         nargin = 1;
    %     end
    
    if (nargin == 0)
        
        % Simply launch the viewer without any data:
        system([viewer '&']);
        
    else
        
        ivFileNames = {'',''};
        ivAnimated = {0,0};
        ivFileIdx = 1;
        
        i=1;
        while (i<=nargin)
            jump_step = 0;
            if ischar(varargin{i}) % Filename
                
                if exist(varargin{i},'file')
                    
                    [~,~,ext_str] = fileparts(varargin{i});
                    
                    if strcmp(ext_str,'.bin')
                        
                        ivFileNames{ivFileIdx} = varargin{i};
                        
                    elseif strcmp(ext_str,'.mat')
                        
                        mat = load(varargin{i});
                        if ((i+1 <= nargin) && isfield(mat,varargin{i+1}))
                            zimg = getfield(mat,varargin{i+1}); %#ok<GFLD>
                            jump_step = jump_step + 1;
                            
                            if ((i+2 <= nargin) && isnumeric(varargin{i+2}) && isscalar(varargin{i+2})),
                                zimg = zimg{varargin{i+2}};
                                jump_step = jump_step + 1;
                            end
                            
                            tmpFileName = [tempname '.bin'];
                            [ivFileNames{ivFileIdx},ivAnimated{ivFileIdx}] = saveBinFile(tmpFileName,zimg);
                            
                        end
                        
                        if isempty(ivFileNames{ivFileIdx})
                            error('ivbin_viewer.m','Insufficent information to select from mat file.');
                        end
                        
                    else
                        error('ivbin_viewer.m','Unsupported file type');
                    end
                    
                else
                    error('ivbin_viewer.m', ['The file ' varargin{i} ' does not exist.']);
                end
                
            elseif (iscell(varargin{i}) || isnumeric(varargin{i})) % Cell array or 2D/3D matrix of depth frames
                
                try
                    tmpFileName = [tempname '.bin'];
                    [ivFileNames{ivFileIdx},ivAnimated{ivFileIdx}] = saveBinFile(tmpFileName,varargin{i});
                    
                catch err
                    rethrow(err);
                end
                
            else
                
                error('ivbin_viewer.m','Unsupported data format.');
                
            end
            
            i = i+jump_step+1;
            ivFileIdx = ivFileIdx + 1;
            
        end
        
        % Launch IVBinViewer:
        if (~ivAnimated{1} && ~ivAnimated{2}) % run a single instance of ivViewer
            system([viewer ' "' ivFileNames{1} '" ' ivFileNames{2} ' &']);
        else
            system([viewer ' ' ivFileNames{1} ' &']);
            if ~isempty(ivFileNames{2})
                system([viewer ' ' ivFileNames{2} ' &']);
            end
        end
    end
    
    
    
    % DO NOT DELETE THE TEMP FILE!!!
    % An async call is used for the viewer, meaning that the file may be
    % deleted before it is read.
    %delete(tmpFileName);
end


function [retFilename,isAnimated] = saveBinFile(filename, img)

    [path_str,name_str,ext_str] = fileparts(filename);

    if iscell(img)
        imgCells = img;
    elseif isnumeric(img) % A 2D or 3D matrix
        if (ndims(img) > 3)
            error('save_bin_file','Unsupported matrix dimension.'); %#ok<*CTPCT>
        else
            imgCells{1} = img;
        end
    else
        error('save_bin_file','Unsupported data format.');
    end

    withIR = false;
    if (ndims(imgCells{1}) == 3 && isa(imgCells{1}, 'single'))
        typeVertices = true;
    elseif (ismatrix(imgCells{1}) && isa(imgCells{1}, 'uint16'))
        typeVertices = false;
    else
        error('ivbin_viewer:save_bin_file','Unsupported data format.\n Only depth image of uint16 and 3d xyz matrix of single are supported.');
    end
            
    
    imgStreams = {};
    iStream = 1;
    i = 1;
    while (i <= length(imgCells))
        if (ismatrix(imgCells{i}))
            z = imgCells{i}';
            zBytes = reshape(typecast(z(:), 'uint8'),2,[]);
        else
            z = permute(imgCells{i}, [3,2,1]);
            zBytes = reshape(typecast(z(:), 'uint8'),12,[]);
        end
        
        if (i < length(imgCells) && isa(imgCells{i+1},'uint8'))
            ir = imgCells{i+1}';
            imgStreams{iStream} = [zBytes;ir(:)'];
            i = i + 1;
            withIR = true;
        else
            imgStreams{iStream} = zBytes;
        end
        iStream = iStream + 1;
        i = i + 1;
    end
    
    if (length(imgStreams) > 1)
        isAnimated = 1;
    else
        isAnimated = 0;
    end
    
    if (typeVertices)
        ext_str = [ext_str 'v'];
    else
        ext_str = [ext_str 'z'];
    end
        
    if (withIR)
        ext_str = [ext_str 'i'];
    end
    
    retFilename = [fullfile(path_str,[name_str '_0000']) ext_str];
    
    for i=1:length(imgStreams)
        temporal_filename = [fullfile(path_str,[name_str sprintf('_%04d',i-1)]) ext_str];
        fid = fopen(temporal_filename,'wb');
        if (fid == 0)
            error('save_bin_file','Cannot open bin file for writing');
        end
        
        fwrite(fid, imgStreams{i});
        fclose(fid);
    end

end
