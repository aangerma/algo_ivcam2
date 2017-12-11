function [] = writeBin(fname,data,varargin)
if(isstruct(data) && length(data)~=1)
    [bd,fn,ext]=fileparts(fname);
    for i=1:length(data)
        newfn=sprintf('%s%s%s_%04d%s',bd,filesep,fn,i,ext);
        io.writeBin(newfn,data(i),varargin{:});
    end
    return;
end

p = inputParser;

addRequired(p,'fname',@ischar);
addRequired(p,'data');

fname = strrep(fname,'"','');
[folder,file,ext] = fileparts(fname);

defaultType = ext(2:end);

expectedTypes = {'binz','bini','binr','binv','binc','bint','bin8','bin12','bin16','bin32','stl','binzi','binvi'};

addParameter(p,'type',defaultType,...
    @(x) any(validatestring(x,expectedTypes)));

parse(p,fname,data,varargin{:});

if isempty(p.Results.type)
    error('Without fname extension, ''type'' must be specified!');
end

fullname = fullfile(folder,[file,ext]);
[f,err] = fopen(fullname,'wb');
if(~isempty(err))
    error([fullname ': ' err])
end
switch p.Results.type
    case 'binz'
        fwrite(f,data,'uint16');
    case 'bini'
        fwrite(f,data,'uint16');
    case 'binr'
        
        data(isnan(data))=0;
        data = max(min(data,2^13-1),0);
        data16 = uint16(data*8);%assumes max depth of 2^13. mult by 2^3 for sub millimeter reslution.
        fwrite(f,vec(data16'),'uint16');
    case 'binv'
        
        vertices =[vec(flipud(data(:,:,1))') vec(flipud(data(:,:,2))') vec(flipud(data(:,:,3))')]';
        fwrite(f,vertices(:),'float');
    case 'binc'
        fwrite(f,vec(data'),'uint16');
    case 'bint'
        rgb =[vec(data(:,:,1)') vec(data(:,:,2)') vec(data(:,:,3)')]';
        fwrite(f,rgb(:),'uint8');
    case 'stl'
        stlwriteMatrix(f,data.xImg,data.yImg,data.zImg,'color',double(data.iImg),'verbose',false,'facetsDirUp',false);
    case {'bin8','bin12','bin16','bin32'}
        ubitn = strrep(p.Results.type,'bin','ubit');
        fwrite(f,vec(data'),ubitn);
    case 'binzi'
        assert(isfield(data,'zImg') && isfield(data,'iImg'))
        assert(isa(data.zImg,'uint16'),'z must be uint16');
        assert(isa(data.iImg,'uint8' ),'i must be uint16');
        zBytes = reshape(typecast(vec(data.zImg'), 'uint8'),2,[]);
        fwrite(f,[zBytes;vec(data.iImg')']);
        %vec([reshape(typecast(vec(data.zImg'),'uint8'),2,[])' vec(data.iImg')]),'uint8');
    case 'binvi'
        assert(isfield(data,'vImg') && isfield(data,'iImg'))
        assert(isa(data.vImg,'single'),'z must be uint16');
        assert(size(data.vImg,3)==3);
        assert(isa(data.iImg,'uint8' ),'i must be uint16');
        xyz = permute(data.vImg, [3,2,1]);
        xyzBytes = reshape(typecast(vec(xyz), 'uint8'),12,[]);
        fwrite(f,[xyzBytes;vec(data.iImg')']);
    otherwise
        error('unknonw extention');
end
fclose(f);
end


